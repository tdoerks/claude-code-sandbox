export interface VolumeMount {
  source: string;
  target: string;
  readonly?: boolean;
}

export interface SandboxConfig {
  dockerImage?: string;
  dockerfile?: string;
  containerPrefix?: string;
  autoPush?: boolean;
  autoCreatePR?: boolean;
  autoStartClaude?: boolean;
  defaultShell?: "claude" | "bash";
  claudeConfigPath?: string;
  setupCommands?: string[];
  environment?: Record<string, string>;
  envFile?: string;
  volumes?: string[];
  mounts?: VolumeMount[];
  allowedTools?: string[];
  maxThinkingTokens?: number;
  bashTimeout?: number;
  includeUntracked?: boolean;
  targetBranch?: string;
  remoteBranch?: string;
  prNumber?: string;
  dockerSocketPath?: string;
  // Path to a directory containing skill .zip files (or unzipped skill folders)
  // to inject into the container at launch (into /home/claude/.claude/skills).
  skillsPath?: string;
  // Container network mode. "bridge" = full internet (default),
  // "allowlist" = egress restricted to Anthropic API + GitHub (+allowedDomains),
  // "none" = no network (Claude inference will not work).
  networkMode?: "bridge" | "allowlist" | "none";
  // Extra domains to permit when networkMode is "allowlist".
  allowedDomains?: string[];
}

export interface Credentials {
  claude?: {
    type: "api_key" | "oauth" | "bedrock" | "vertex";
    value: string;
    region?: string;
    project?: string;
  };
  github?: {
    token?: string;
    gitConfig?: string;
  };
}

export interface CommitInfo {
  hash: string;
  author: string;
  date: string;
  message: string;
  files: string[];
}
