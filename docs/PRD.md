# PRD: GitHub MCP Server MCPB Builder

## Overview

This project automates building and releasing `.mcpb` (MCP Bundle) files for the [GitHub MCP Server](https://github.com/github/github-mcp-server). MCPB files are installable bundles for Claude Desktop that package a pre-built MCP server binary with a manifest describing its configuration, tools, and user-facing settings.

## Problem

Users who want to use the GitHub MCP Server with Claude Desktop need to manually download the binary, configure it, and set up the MCP server entry. An `.mcpb` bundle provides a one-click install experience.

GitHub does not ship `.mcpb` files themselves, so this project fills that gap by tracking upstream releases and producing bundles for all supported platforms.

## Goals

1. **Automated tracking** — Detect new releases of `github/github-mcp-server` and build `.mcpb` bundles automatically.
2. **Cross-platform** — Produce bundles for all platform/architecture combinations that upstream supports (Linux, macOS, Windows × x86_64, arm64, and i386 where available).
3. **Reliable releases** — One GitHub Release in this repo per upstream version, with all platform `.mcpb` files attached as assets.
4. **Manual trigger** — The workflow can also be triggered manually via the GitHub Actions UI (workflow_dispatch), with an optional version override.

## Non-Goals

- Modifying the upstream binary in any way.
- Building the GitHub MCP Server from source.
- Hosting a package registry or update server.

## Architecture

### MCPB Format

An `.mcpb` file is a ZIP archive containing:

```
manifest.json        # Bundle metadata, tool declarations, user config schema
server/
  github-mcp-server  # The platform-specific binary (or .exe on Windows)
```

### manifest.json

The manifest declares:

- **Identity**: name, display name, version, description, author, license
- **Server config**: binary entry point, CLI args (`stdio`), environment variables (GitHub token, toolsets, host), platform overrides (Windows `.exe`)
- **Tools**: list of MCP tools the server exposes
- **User config schema**: fields Claude Desktop prompts the user for (token, toolsets, enterprise host)

The version field in the manifest is updated to match the upstream release version at build time.

### Workflow

A GitHub Actions workflow (`.github/workflows/build.yml`) runs:

- **On schedule**: Every 4 hours via cron (`0 */4 * * *`)
- **On demand**: Via `workflow_dispatch` with an optional `version` input

#### Steps

1. **Determine version** — If triggered by dispatch with a version input, use that. Otherwise, fetch the latest release tag from `github/github-mcp-server` via the GitHub API.
2. **Check for existing release** — Query this repo's releases. If a release for this version already exists, skip (exit early). This makes the cron runs idempotent.
3. **Build matrix** — Run a matrix build across all platform/arch combinations that upstream ships:
   - `Darwin/x86_64`, `Darwin/arm64`
   - `Linux/x86_64`, `Linux/arm64`, `Linux/i386`
   - `Windows/x86_64`, `Windows/arm64`, `Windows/i386`
4. **For each matrix entry**:
   - Download the matching release asset from upstream:
     - Linux/macOS: `github-mcp-server_{Platform}_{Arch}.tar.gz`
     - Windows: `github-mcp-server_Windows_{Arch}.zip`
   - Download the checksums file (`github-mcp-server_{version}_checksums.txt`) and verify the asset integrity
   - Extract the binary
   - Copy and version-stamp `manifest.json`
   - Package into `github-mcp-server-{version}-{platform}-{arch}.mcpb` (ZIP)
5. **Create GitHub Release** — Create a release tagged `v{version}` with all `.mcpb` files attached. Release notes should link to the upstream release.

#### Error Handling

- If an upstream asset doesn't exist for a given platform/arch combo (e.g., upstream drops or hasn't added a target), that matrix job should fail gracefully and the remaining builds should still complete. The release should include whatever was successfully built.

### Repository Structure

```
.github/
  workflows/
    build.yml          # The CI workflow
build.sh               # Local build script (retained for manual/local use)
manifest.json          # Template manifest
docs/
  PRD.md               # This document
.gitignore             # Ignore *.mcpb, logs/, etc.
README.md              # Usage instructions
```

## Release Naming

- **Git tag**: `v{upstream_version}` (e.g., `v0.32.0`)
- **Release title**: `GitHub MCP Server v{upstream_version}`
- **Asset names**: `github-mcp-server-{version}-{platform}-{arch}.mcpb`
  - Platform values: `Darwin`, `Linux`, `Windows`
  - Arch values: `x86_64`, `arm64`, `i386` (matching upstream naming conventions)

## Success Criteria

1. Within 4 hours of a new `github/github-mcp-server` release, corresponding `.mcpb` files are available as GitHub Release assets in this repo.
2. The `.mcpb` files install correctly in Claude Desktop on all supported platforms.
3. The workflow is idempotent — re-running for an already-released version is a no-op.
