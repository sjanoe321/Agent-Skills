#!/bin/bash
#
# Installs Copilot agent skills from this repository.
#
# Usage:
#   ./install.sh <personal|project> [--force] [--skills skill1,skill2]
#   ./install.sh --help

set -euo pipefail

show_usage() {
    echo "Usage: ./install.sh <personal|project> [--force] [--skills skill1,skill2]"
    echo ""
    echo "Arguments:"
    echo "  personal           Install to ~/.copilot/skills/"
    echo "  project            Install to .github/skills/ in the current directory"
    echo ""
    echo "Options:"
    echo "  --force            Overwrite existing skills without prompting"
    echo "  --skills LIST      Comma-separated list of specific skills to install"
    echo "  --help             Show this help message"
}

# Resolve the script's own directory to locate skills/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skills"

TARGET=""
FORCE=false
SKILLS_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        personal|project)
            TARGET="$1"
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --skills)
            if [[ $# -lt 2 ]]; then
                echo "Error: --skills requires a comma-separated list." >&2
                exit 1
            fi
            SKILLS_FILTER="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            show_usage
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    show_usage
    exit 0
fi

# Validate source directory
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Skills directory not found at: $SOURCE_DIR" >&2
    exit 1
fi

# Determine destination
if [[ "$TARGET" == "personal" ]]; then
    DEST_DIR="$HOME/.copilot/skills"
else
    DEST_DIR="$(pwd)/.github/skills"
fi

# Gather available skills (subdirectories of skills/)
mapfile -t ALL_SKILLS < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

if [[ ${#ALL_SKILLS[@]} -eq 0 ]]; then
    echo "Warning: No skills found in: $SOURCE_DIR"
    exit 0
fi

# Filter to requested skills if specified
if [[ -n "$SKILLS_FILTER" ]]; then
    IFS=',' read -ra REQUESTED <<< "$SKILLS_FILTER"
    SKILLS_TO_INSTALL=()
    for req in "${REQUESTED[@]}"; do
        req="$(echo "$req" | xargs)" # trim whitespace
        found=false
        for skill in "${ALL_SKILLS[@]}"; do
            if [[ "$skill" == "$req" ]]; then
                SKILLS_TO_INSTALL+=("$skill")
                found=true
                break
            fi
        done
        if ! $found; then
            echo "Warning: Skill not found: $req"
        fi
    done
else
    SKILLS_TO_INSTALL=("${ALL_SKILLS[@]}")
fi

if [[ ${#SKILLS_TO_INSTALL[@]} -eq 0 ]]; then
    echo "Warning: No matching skills to install."
    exit 0
fi

# Ensure destination directory exists
if [[ ! -d "$DEST_DIR" ]]; then
    mkdir -p "$DEST_DIR"
    echo "Created destination directory: $DEST_DIR"
fi

INSTALLED_COUNT=0
FORCE_ALL=$FORCE

for skill in "${SKILLS_TO_INSTALL[@]}"; do
    skill_src="$SOURCE_DIR/$skill"
    skill_dest="$DEST_DIR/$skill"

    if [[ -d "$skill_dest" ]]; then
        if $FORCE_ALL; then
            echo "  Overwriting: $skill"
            rm -rf "$skill_dest"
        else
            read -rp "  Skill '$skill' already exists at $skill_dest. Overwrite? [y/N/a(ll)] " response
            case "$response" in
                a|all)
                    FORCE_ALL=true
                    echo "  Overwriting: $skill"
                    rm -rf "$skill_dest"
                    ;;
                y|yes)
                    echo "  Overwriting: $skill"
                    rm -rf "$skill_dest"
                    ;;
                *)
                    echo "  Skipping: $skill"
                    continue
                    ;;
            esac
        fi
    else
        echo "  Installing: $skill"
    fi

    if cp -r "$skill_src" "$skill_dest" 2>/dev/null; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        echo "  Error: Failed to install '$skill'" >&2
    fi
done

echo ""
echo "Installed $INSTALLED_COUNT skills to $DEST_DIR"
