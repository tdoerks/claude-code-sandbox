#!/bin/bash
#
# init-firewall.sh — egress allowlist for claude-code-sandbox
#
# Locks the container's outbound network down to a small allowlist:
#   - Anthropic API (so Claude Code inference keeps working)
#   - GitHub (so git push / PR creation works)
#   - DNS (so names can be resolved)
#   - any extra domains passed via SANDBOX_ALLOWED_DOMAINS (comma-separated)
#
# Everything else is dropped. Requires the container to have the NET_ADMIN
# capability (claude-sandbox adds it automatically in allowlist mode).
#
# Modeled on Anthropic's Claude Code devcontainer firewall.

set -euo pipefail

echo "[firewall] Starting egress allowlist setup..."

# --- Preconditions -----------------------------------------------------------
if ! command -v iptables >/dev/null 2>&1; then
  echo "[firewall] ERROR: iptables not installed" >&2
  exit 1
fi
if ! command -v ipset >/dev/null 2>&1; then
  echo "[firewall] ERROR: ipset not installed" >&2
  exit 1
fi

# Verify we actually have NET_ADMIN by attempting a harmless list.
if ! iptables -L >/dev/null 2>&1; then
  echo "[firewall] ERROR: cannot manage iptables (missing NET_ADMIN capability?)" >&2
  exit 1
fi

# --- Reset any existing rules -------------------------------------------------
iptables -F
iptables -X || true
iptables -t nat -F || true
iptables -t nat -X || true
iptables -t mangle -F || true
iptables -t mangle -X || true

ipset destroy allowed-domains 2>/dev/null || true
ipset create allowed-domains hash:net

# --- Base allowances (before default DROP) -----------------------------------
# Loopback
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# DNS (needed to resolve the allowlist itself and at runtime)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
iptables -A INPUT  -p tcp --sport 53 -j ACCEPT

# Established/related return traffic
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# --- Build the allowlist ------------------------------------------------------
add_host() {
  local host="$1"
  local ips
  ips=$(dig +short A "$host" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
  if [ -z "$ips" ]; then
    echo "[firewall]   ! could not resolve $host"
    return
  fi
  while IFS= read -r ip; do
    [ -n "$ip" ] || continue
    ipset add allowed-domains "$ip" 2>/dev/null || true
  done <<< "$ips"
  echo "[firewall]   + $host"
}

add_cidr() {
  local cidr="$1"
  [ -n "$cidr" ] || return
  ipset add allowed-domains "$cidr" 2>/dev/null || true
}

# Anthropic (Claude Code inference + app)
DEFAULT_DOMAINS=(
  "api.anthropic.com"
  "claude.ai"
  "console.anthropic.com"
)
echo "[firewall] Adding Anthropic endpoints..."
for d in "${DEFAULT_DOMAINS[@]}"; do
  add_host "$d"
done

# Extra user-specified domains (comma-separated)
if [ -n "${SANDBOX_ALLOWED_DOMAINS:-}" ]; then
  echo "[firewall] Adding extra allowed domains..."
  IFS=',' read -ra EXTRA <<< "${SANDBOX_ALLOWED_DOMAINS}"
  for d in "${EXTRA[@]}"; do
    d="$(echo "$d" | xargs)" # trim
    [ -n "$d" ] && add_host "$d"
  done
fi

# GitHub: pull published IP ranges from the meta API, plus resolve key hosts.
echo "[firewall] Adding GitHub ranges..."
GH_META="$(curl -fsSL --max-time 10 https://api.github.com/meta 2>/dev/null || true)"
if [ -n "$GH_META" ] && command -v jq >/dev/null 2>&1; then
  for key in web api git; do
    while IFS= read -r cidr; do
      # Only IPv4 CIDRs (ipset set is hash:net IPv4)
      if echo "$cidr" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$'; then
        add_cidr "$cidr"
      fi
    done < <(echo "$GH_META" | jq -r ".${key}[]?" 2>/dev/null || true)
  done
  echo "[firewall]   + github meta (web/api/git)"
else
  echo "[firewall]   ! github meta unavailable, falling back to host resolution"
fi
# Always also resolve the common hosts directly as a fallback
for d in github.com api.github.com codeload.github.com; do
  add_host "$d"
done

# --- Default-deny policy ------------------------------------------------------
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow outbound only to the allowlist
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# --- Verify -------------------------------------------------------------------
echo "[firewall] Verifying..."
if curl -fsS --max-time 5 https://api.github.com/zen >/dev/null 2>&1; then
  echo "[firewall]   ok: api.github.com reachable"
else
  echo "[firewall]   ! warning: api.github.com not reachable"
fi
if curl -fsS --max-time 5 https://example.com >/dev/null 2>&1; then
  echo "[firewall]   ! warning: example.com IS reachable (allowlist not effective)" >&2
else
  echo "[firewall]   ok: example.com blocked"
fi

echo "[firewall] Egress allowlist active."
