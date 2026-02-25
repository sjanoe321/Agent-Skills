---
name: gh-cli
description: GitHub CLI (gh) comprehensive reference for repositories, issues, pull requests, Actions, projects, releases, gists, codespaces, organizations, extensions, and all GitHub operations from the command line.
---

# GitHub CLI (gh)

Comprehensive reference for GitHub CLI (gh) - work seamlessly with GitHub from the command line.

## Prerequisites

### Installation

```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Windows
winget install --id GitHub.cli

# Verify installation
gh --version
```

### Authentication

```bash
# Interactive login (default: github.com)
gh auth login

# Login with specific hostname
gh auth login --hostname enterprise.internal

# Login with token
gh auth login --with-token < mytoken.txt

# Check authentication status
gh auth status

# Switch accounts
gh auth switch --hostname github.com --user username

# Logout
gh auth logout --hostname github.com --user username
```

### Setup Git Integration

```bash
# Configure git to use gh as credential helper
gh auth setup-git

# View active token
gh auth token

# Refresh authentication scopes
gh auth refresh --scopes write:org,read:public_key
```

## CLI Structure

```
gh                          # Root command
├── auth                    # Authentication
│   ├── login / logout / refresh / setup-git / status / switch / token
├── browse                  # Open in browser
├── codespace               # GitHub Codespaces
│   ├── code / cp / create / delete / edit / jupyter / list / logs / ports / rebuild / ssh / stop / view
├── gist                    # Gists
│   ├── clone / create / delete / edit / list / rename / view
├── issue                   # Issues
│   ├── create / list / status / close / comment / delete / develop / edit / lock / pin / reopen / transfer / unlock / view
├── org                     # Organizations
│   └── list
├── pr                      # Pull Requests
│   ├── create / list / status / checkout / checks / close / comment / diff / edit / lock / merge / ready / reopen / revert / review / unlock / update-branch / view
├── project                 # Projects
│   ├── close / copy / create / delete / edit / field-create / field-delete / field-list / item-add / item-archive / item-create / item-delete / item-edit / item-list / link / list / mark-template / unlink / view
├── release                 # Releases
│   ├── create / list / delete / delete-asset / download / edit / upload / verify / verify-asset / view
├── repo                    # Repositories
│   ├── create / list / archive / autolink / clone / delete / deploy-key / edit / fork / gitignore / license / rename / set-default / sync / unarchive / view
├── cache                   # Actions caches
│   ├── delete / list
├── run                     # Workflow runs
│   ├── cancel / delete / download / list / rerun / view / watch
├── workflow                # Workflows
│   ├── disable / enable / list / run / view
├── api                     # API requests
├── extension               # Extensions
│   ├── browse / create / exec / install / list / remove / search / upgrade
├── label                   # Labels
│   ├── clone / create / delete / edit / list
├── search                  # Search
│   ├── code / commits / issues / prs / repos
├── secret                  # Secrets
│   ├── delete / list / set
├── ssh-key                 # SSH keys
│   ├── add / delete / list
└── variable                # Variables
    ├── delete / get / list / set
```

## Repository Operations

### Create and Manage

```bash
# Create new repository
gh repo create my-project --public --description "My project" --clone

# Clone repository
gh repo clone owner/repo

# Fork repository
gh repo fork owner/repo --clone

# View repository info
gh repo view owner/repo

# Edit repository settings
gh repo edit --default-branch main --enable-issues --enable-wiki=false

# Sync fork with upstream
gh repo sync
```

## Issue Operations

```bash
# Create issue
gh issue create --title "Bug: login fails" --body "Steps to reproduce..." --label bug

# List issues
gh issue list --state open --label "bug" --assignee "@me"

# View issue
gh issue view 123

# Close issue
gh issue close 123 --comment "Fixed in PR #456"

# Create branch from issue
gh issue develop 123 --branch feature/fix-login
```

## Pull Request Operations

```bash
# Create PR
gh pr create --title "Fix login bug" --body "Closes #123" --reviewer user1,user2

# List PRs
gh pr list --state open --author "@me"

# Checkout PR
gh pr checkout 456

# View PR diff
gh pr diff 456

# Merge PR
gh pr merge 456 --squash --delete-branch

# Review PR
gh pr review 456 --approve --body "LGTM!"
```

## GitHub Actions

```bash
# List workflows
gh workflow list

# Run workflow
gh workflow run ci.yml --ref main

# List runs
gh run list --workflow ci.yml --status failure

# Watch a run
gh run watch 12345

# View run details
gh run view 12345

# Download artifacts
gh run download 12345 --dir ./artifacts

# Rerun failed jobs
gh run rerun 12345 --failed
```

## API Requests

```bash
# GET request
gh api repos/owner/repo

# POST request
gh api repos/owner/repo/issues -f title="New issue" -f body="Description"

# GraphQL query
gh api graphql -f query='{ viewer { login } }'

# Paginated request
gh api repos/owner/repo/issues --paginate
```

## Output Formatting

### JSON Output

```bash
# Basic JSON
gh repo view --json name,description

# Filter with jq
gh pr list --json number,title --jq '.[] | select(.number > 100)'

# Complex queries
gh issue list --json number,title,labels \
  --jq '.[] | {number, title: .title, tags: [.labels[].name]}'
```

## Common Workflows

### Create PR from Issue

```bash
gh issue develop 123 --branch feature/issue-123
git add . && git commit -m "Fix issue #123"
git push
gh pr create --title "Fix #123" --body "Closes #123"
```

### Bulk Operations

```bash
# Close stale issues
gh issue list --search "label:stale" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --comment "Closing as stale"
```

### CI/CD Workflow

```bash
# Run workflow and watch
gh workflow run ci.yml --ref main
gh run list --workflow ci.yml --limit 1 --json databaseId --jq '.[0].databaseId' | \
  xargs gh run watch
```

## Global Flags

| Flag | Description |
|------|-------------|
| `--help` / `-h` | Show help for command |
| `--repo [HOST/]OWNER/REPO` | Select another repository |
| `--json FIELDS` | Output JSON with specified fields |
| `--jq EXPRESSION` | Filter JSON output |
| `--template STRING` | Format JSON using Go template |
| `--web` | Open in browser |

## Best Practices

1. **Set default repo**: `gh repo set-default owner/repo`
2. **Use JSON + jq** for scripting: `gh pr list --json number,title --jq '...'`
3. **Paginate large results**: `gh issue list --state all --paginate`
4. **Environment variables**: `export GH_TOKEN=$(gh auth token)` for automation

## References

- Official Manual: https://cli.github.com/manual/
- GitHub Docs: https://docs.github.com/en/github-cli
- REST API: https://docs.github.com/en/rest
- GraphQL API: https://docs.github.com/en/graphql
