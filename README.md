# GitHub MCP Server - MCPB Bundles

Automated `.mcpb` bundle builds for the [GitHub MCP Server](https://github.com/github/github-mcp-server), for use with Claude Desktop.

## Installation

1. Go to [Releases](../../releases)
2. Download the `.mcpb` file for your platform
3. Open it in Claude Desktop

## Platforms

| Platform | Architectures |
|----------|--------------|
| macOS | arm64 (Apple Silicon), x86_64 (Intel) |
| Linux | x86_64, arm64, i386 |
| Windows | x86_64, arm64, i386 |

## How it works

A GitHub Actions workflow runs every 4 hours to check for new releases of `github/github-mcp-server`. When a new version is detected, it downloads the pre-built binaries, packages them with a `manifest.json` into `.mcpb` bundles, and creates a GitHub Release with all platform variants attached.

## License

The GitHub MCP Server is licensed under [MIT](https://github.com/github/github-mcp-server/blob/main/LICENSE) by GitHub. This repo only packages it for distribution.
