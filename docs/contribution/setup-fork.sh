#!/bin/bash

################################################################################
# ProxmoxVED Fork Setup Script
#
# Automatically configures documentation and scripts for your fork
# Detects your GitHub username and repository from git config
# Updates all hardcoded links to point to your fork
#
# Usage:
#   bash docs/contribution/setup-fork.sh
#   bash docs/contribution/setup-fork.sh YOUR_USERNAME
#   bash docs/contribution/setup-fork.sh YOUR_USERNAME REPO_NAME
#   bash docs/contribution/setup-fork.sh YOUR_USERNAME/REPO_NAME
#   bash docs/contribution/setup-fork.sh https://github.com/YOUR_USERNAME/REPO_NAME
#   bash docs/contribution/setup-fork.sh --yes
#
# Examples:
#   bash docs/contribution/setup-fork.sh john
#   bash docs/contribution/setup-fork.sh john my-fork
#   bash docs/contribution/setup-fork.sh john/my-fork
################################################################################

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_NAME="ProxmoxVED"
USERNAME=""
ASSUME_YES=false
FILES_UPDATED=0

################################################################################
# FUNCTIONS
################################################################################

print_header() {
  echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} ProxmoxVED Fork Setup Script"
  echo -e "${BLUE}║${NC} Configuring for your fork..."
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_info() {
  echo -e "${BLUE}ℹ${NC}  $1"
}

print_success() {
  echo -e "${GREEN}✓${NC}  $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
  echo -e "${RED}✗${NC}  $1"
}

show_usage() {
  cat <<EOF
Usage:
  bash docs/contribution/setup-fork.sh [OPTIONS] [USERNAME|USERNAME/REPO|FORK_URL] [REPO_NAME]

Options:
  --full     Deprecated alias for the default auto-detect behavior
  --yes      Skip the confirmation prompt
  --help     Show this help message

Examples:
  bash docs/contribution/setup-fork.sh
  bash docs/contribution/setup-fork.sh peterder72
  bash docs/contribution/setup-fork.sh peterder72 ProxmoxVED
  bash docs/contribution/setup-fork.sh peterder72/ProxmoxVED
  bash docs/contribution/setup-fork.sh https://github.com/peterder72/ProxmoxVED
EOF
}

extract_github_path() {
  local input="$1"
  local path

  case "$input" in
    git@github.com:*)
      path="${input#git@github.com:}"
      ;;
    https://github.com/*)
      path="${input#https://github.com/}"
      ;;
    http://github.com/*)
      path="${input#http://github.com/}"
      ;;
    github.com/*)
      path="${input#github.com/}"
      ;;
    */*)
      path="$input"
      ;;
    *)
      return 1
      ;;
  esac

  path="${path%/}"
  path="${path%.git}"
  [[ "$path" == */* ]] || return 1
  echo "$path"
}

parse_fork_input() {
  local repo_path

  repo_path=$(extract_github_path "$1") || return 1
  USERNAME="${repo_path%%/*}"
  REPO_NAME="${repo_path##*/}"
}

detect_origin_path() {
  local remote_url

  remote_url=$(git config --get remote.origin.url 2>/dev/null) || return 1
  extract_github_path "$remote_url"
}

detect_username() {
  local repo_path

  repo_path=$(detect_origin_path) || return 1
  echo "${repo_path%%/*}"
}

detect_repo_name() {
  local repo_path

  repo_path=$(detect_origin_path) || return 1
  echo "${repo_path##*/}"
}

replace_links_in_file() {
  local file="$1"
  local old_repo="$2"
  local old_name="$3"
  local new_owner="$4"
  local new_repo="$5"
  local count

  count=$(grep -E -c "https://raw\\.githubusercontent\\.com/${old_repo}/${old_name}|https://github\\.com/${old_repo}/${old_name}/(blob|raw)/" "$file" 2>/dev/null || true)
  if [[ ${count:-0} -gt 0 ]]; then
    sed -i.bak "s|https://raw.githubusercontent.com/$old_repo/$old_name|https://raw.githubusercontent.com/$new_owner/$new_repo|g" "$file"
    sed -i.bak "s|https://github.com/$old_repo/$old_name/blob/|https://github.com/$new_owner/$new_repo/blob/|g" "$file"
    sed -i.bak "s|https://github.com/$old_repo/$old_name/raw/|https://github.com/$new_owner/$new_repo/raw/|g" "$file"
    rm -f "${file}.bak"

    FILES_UPDATED=$((FILES_UPDATED + 1))
    print_success "Updated $file ($count links)"
  fi
}

# Ask user for confirmation
confirm() {
  local prompt="$1"
  local response

  printf "%b%s (y/n)%b " "$YELLOW" "$prompt" "$NC"
  read -r response || return 1
  [[ $response =~ ^[Yy]$ ]]
}

# Update links in files
update_links() {
  local old_repo="community-scripts"
  local old_name="ProxmoxVED"
  local new_owner="$1"
  local new_repo="$2"
  FILES_UPDATED=0

  print_info "Scanning for hardcoded links..."

  # Update ALL shell scripts and markdown files that contain the repo URL
  # This includes ct/, install/, misc/, vm/, tools/, docs/

  echo ""

  # Find all .sh files and update them
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      replace_links_in_file "$file" "$old_repo" "$old_name" "$new_owner" "$new_repo"
    fi
  done < <(find . -type f \( -name "*.sh" -o -name "*.func" \) -not -path "./.git/*" -print0)

  # Also update markdown docs
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      replace_links_in_file "$file" "$old_repo" "$old_name" "$new_owner" "$new_repo"
    fi
  done < <(find ./docs -type f -name "*.md" -print0 2>/dev/null)

  echo ""
  echo "Total files updated: $FILES_UPDATED"
}

# Create user git config setup info
create_git_setup_info() {
  cat >.git-setup-info <<'EOF'
# Git Configuration for ProxmoxVED Development

## Recommended Git Configuration

### Set up remotes for easy syncing with upstream:

```bash
# View your current remotes
git remote -v

# If you don't have 'upstream' configured, add it:
git remote add upstream https://github.com/community-scripts/ProxmoxVED.git

# Verify both remotes exist:
git remote -v
# Should show:
# origin     https://github.com/YOUR_USERNAME/ProxmoxVED.git (fetch)
# origin     https://github.com/YOUR_USERNAME/ProxmoxVED.git (push)
# upstream   https://github.com/community-scripts/ProxmoxVED.git (fetch)
# upstream   https://github.com/community-scripts/ProxmoxVED.git (push)
```

### Configure Git User (if not done globally)

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Or configure globally:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Useful Git Workflows

**Keep your fork up-to-date:**
```bash
git fetch upstream
git rebase upstream/main
git push origin main
```

**Create feature branch:**
```bash
git checkout -b feature/my-awesome-app
# Make changes...
git commit -m "feat: add my awesome app"
git push origin feature/my-awesome-app
```

**Pull latest from upstream:**
```bash
git fetch upstream
git merge upstream/main
```

---

For more help, see: docs/contribution/README.md
EOF

  print_success "Created .git-setup-info file"
}

################################################################################
# MAIN LOGIC
################################################################################

print_header

# Parse command line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_usage
      exit 0
      ;;
    --yes|-y)
      ASSUME_YES=true
      ;;
    --full)
      print_warning "Ignoring deprecated --full flag and using auto-detect instead"
      ;;
    -*)
      print_error "Unknown option: $1"
      echo ""
      show_usage
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      ;;
  esac
  shift
done

if [[ ${#POSITIONAL[@]} -gt 2 ]]; then
  print_error "Too many arguments"
  echo ""
  show_usage
  exit 1
fi

if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
  # Try auto-detection
  if username=$(detect_username); then
    USERNAME="$username"
    print_success "Detected GitHub username: $USERNAME"
  else
    print_error "Could not auto-detect GitHub username from git config"
    echo -e "${YELLOW}Please run:${NC}"
    echo "  bash docs/contribution/setup-fork.sh YOUR_USERNAME"
    exit 1
  fi

  if repo_name=$(detect_repo_name); then
    REPO_NAME="$repo_name"
    if [[ "$REPO_NAME" != "ProxmoxVED" ]]; then
      print_info "Detected custom repo name: $REPO_NAME"
    else
      print_success "Using default repo name: ProxmoxVED"
    fi
  fi
elif [[ ${#POSITIONAL[@]} -eq 1 ]]; then
  if ! parse_fork_input "${POSITIONAL[0]}"; then
    USERNAME="${POSITIONAL[0]}"
  fi
else
  USERNAME="${POSITIONAL[0]}"
  REPO_NAME="${POSITIONAL[1]}"
fi

# Validate inputs
if [[ -z "$USERNAME" ]]; then
  print_error "Username cannot be empty"
  exit 1
fi

if [[ -z "$REPO_NAME" ]]; then
  print_error "Repository name cannot be empty"
  exit 1
fi

# Show what we'll do
echo -e "${BLUE}Configuration Summary:${NC}"
echo "  Repository URL: https://github.com/$USERNAME/$REPO_NAME"
echo "  Directories to scan: ct/, install/, misc/, vm/, tools/, docs/"
echo ""

# Ask for confirmation
if [[ "$ASSUME_YES" == false ]] && ! confirm "Apply these changes?"; then
  print_warning "Setup cancelled"
  exit 0
fi

echo ""

# Update all links
update_links "$USERNAME" "$REPO_NAME"
if [[ $FILES_UPDATED -gt 0 ]]; then
  print_success "Updated $FILES_UPDATED files"
else
  print_warning "No links needed updating"
fi

# Create git setup info file
create_git_setup_info

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC} Fork Setup Complete!                                    ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_success "Fork-specific links updated to point to your fork"
print_info "Your fork: https://github.com/$USERNAME/$REPO_NAME"
print_info "Upstream: https://github.com/community-scripts/ProxmoxVED"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review the changes: git diff"
echo "  2. Check .git-setup-info for recommended git workflow"
echo "  3. Start developing: git checkout -b feature/my-app"
echo "  4. Read: docs/contribution/README.md"
echo ""

print_success "Happy contributing! 🚀"
