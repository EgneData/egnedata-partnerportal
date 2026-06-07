#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DRY_RUN=false
YES=false

usage() {
    echo "Usage: $0 [-n|--dry-run] [-y|--yes] [-h|--help]"
    echo ""
    echo "Fast-forward merge develop to main."
    echo "Tagging is handled by the build pipeline after the test gate."
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show what would be done without making changes"
    echo "  -y, --yes        Skip confirmation prompts (for CI/automation)"
    echo "  -h, --help       Show this help message"
    exit 0
}

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry()   { echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1"; }

check_feature_branches() {
    local branches_found=false
    local branch_info=""

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        local merge_base
        merge_base=$(git merge-base "$branch" develop 2>/dev/null) || continue
        local commits_ahead
        commits_ahead=$(git rev-list --count develop.."$branch" 2>/dev/null) || continue
        [[ "$commits_ahead" -eq 0 ]] && continue
        if git merge-base --is-ancestor main "$merge_base" 2>/dev/null; then
            branches_found=true
            local short_base=${merge_base:0:8}
            branch_info+="    $branch ($commits_ahead commits ahead, based on $short_base)\n"
        fi
    done < <(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -v -E '^(main|develop)$')

    if $branches_found; then
        log_warn "Feature branches based on develop found:"
        echo -e "$branch_info"
        echo "  After this release, you may need to rebase these branches:"
        echo "    git checkout <branch> && git rebase develop"
        echo ""
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -y|--yes)     YES=true;     shift ;;
        -h|--help)    usage ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$0 --help' for usage." >&2
            exit 1
            ;;
    esac
done

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

log_info "Working in repository: $REPO_ROOT"

log_info "Fetching latest from remote..."
git fetch origin

CURRENT_BRANCH=$(git branch --show-current)
log_info "Current branch: $CURRENT_BRANCH"

if [[ "$CURRENT_BRANCH" != "develop" ]]; then
    log_error "This script must be run from the 'develop' branch"
    log_info "Switch to develop: git checkout develop"
    exit 1
fi

DEVELOP_LOCAL=$(git rev-parse develop 2>/dev/null || echo "")
DEVELOP_REMOTE=$(git rev-parse origin/develop 2>/dev/null || echo "")
MAIN_LOCAL=$(git rev-parse main 2>/dev/null || echo "")
MAIN_REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "")

[[ -z "$DEVELOP_LOCAL" ]] && { log_error "Local 'develop' branch not found"; exit 1; }
[[ -z "$MAIN_LOCAL" ]]    && { log_error "Local 'main' branch not found"; exit 1; }

if [[ "$DEVELOP_LOCAL" != "$DEVELOP_REMOTE" ]]; then
    log_error "Local 'develop' is not in sync with 'origin/develop'"
    log_info "Local:  $DEVELOP_LOCAL"
    log_info "Remote: $DEVELOP_REMOTE"
    log_info "Pull or push to sync before releasing"
    exit 1
fi

if [[ "$MAIN_LOCAL" != "$MAIN_REMOTE" ]]; then
    log_error "Local 'main' is not in sync with 'origin/main'"
    log_info "Local:  $MAIN_LOCAL"
    log_info "Remote: $MAIN_REMOTE"
    log_info "Pull or push to sync before releasing"
    exit 1
fi

if ! git merge-base --is-ancestor main develop; then
    log_error "Fast-forward merge not possible: 'main' is not an ancestor of 'develop'"
    log_info "Commits on main not in develop:"
    git log --oneline develop..main || true
    exit 1
fi

if [[ "$MAIN_LOCAL" == "$DEVELOP_LOCAL" ]]; then
    log_info "Nothing to merge: 'main' and 'develop' are at the same commit ($MAIN_LOCAL)"
    log_info "Nothing to do."
    exit 0
fi

log_info "Commits to be merged from develop to main:"
git log --oneline main..develop
echo ""

check_feature_branches

log_info "Summary:"
log_info "  Source: develop ($DEVELOP_LOCAL)"
log_info "  Target: main   ($MAIN_LOCAL)"
echo ""

if $DRY_RUN; then
    log_dry "checkout main"
    log_dry "merge --ff-only develop"
    log_dry "push origin main"
    log_dry "checkout $CURRENT_BRANCH"
    echo ""
    log_info "Dry run complete. No changes were made."
    exit 0
fi

if ! $YES; then
    read -rp "Proceed with merge? [y/N] " -n 1
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { log_info "Aborted"; exit 0; }
fi

log_info "Checking out main..."
git checkout main

log_info "Merging develop with fast-forward..."
if ! git merge --ff-only develop; then
    log_error "Fast-forward merge failed"
    git checkout "$CURRENT_BRANCH"
    exit 1
fi

log_info "Pushing main to origin..."
git push origin main

log_info "Returning to branch '$CURRENT_BRANCH'..."
git checkout "$CURRENT_BRANCH"

echo ""
log_info "Merge complete!"
log_info "  Main branch updated and pushed"
log_info "  Build pipeline will compute and apply the release tag after the gate"
