# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a personal experiment workspace for testing Claude capabilities and building skills, agents, and workflows. The devcontainer is infrastructure — the real work is whatever experiment is currently being explored.

Projects here tend to be exploratory: proofs of concept, capability tests, skill/agent prototypes, and workflow automation.

## Working Style

This user comes from an engineering background and follows a disciplined process:

1. **Analyze** — understand the problem fully before touching anything
2. **Plan** — lay out the approach, identify constraints and tradeoffs
3. **Refine** — tighten the plan before writing code
4. **Implement** — execute with precision

**For Claude:** Match this pace. Front-load understanding. Don't jump to solutions. When asked to build something, lead with analysis and a clear plan. Raise constraints and tradeoffs explicitly rather than quietly making assumptions.

## Memory Protocol

## Follow the memory rules at `@.claude/rules/memory-update.md`
## Follow the read chunking rules at `@.claude/rules/iterative-read.md`
## Follow the iterative write rules at `@.claude/rules/iterative-write.md`

## Container Infrastructure

The workspace runs inside a VS Code Dev Container defined in `.devcontainer/`:

- `devcontainer.json` — extensions (Claude Code, ESLint, Prettier, GitLens), volumes, env vars, post-start command
- `Dockerfile` — `node:20` base with git, zsh, fzf, GitHub CLI, jq, and Claude Code installed globally
- `init-firewall.sh` — runs at container startup; restricts outbound traffic via `iptables`/`ipset`

**Firewall allowlist** (hardcoded in `init-firewall.sh`):

- GitHub (IP ranges fetched dynamically from `api.github.com/meta`)
- npm registry (`registry.npmjs.org`)
- Anthropic APIs (`api.anthropic.com`, `statsig.anthropic.com`, `statsig.us`)
- Sentry error tracking
- VS Code services (marketplace, gallery, extension CDN)
- Local Docker DNS (`127.0.0.11`) and Docker host

To add a new allowed host, add the domain to the appropriate `DOMAINS` array in `init-firewall.sh` and restart the container.

**Key env vars:** `NODE_OPTIONS=--max-old-space-size=4096`, `CLAUDE_CONFIG_DIR=/home/node/.claude`, `DEVCONTAINER=true`
