# 🍴 Fork Setup Guide

**Just forked ProxmoxVED? Run this first!**

## Quick Start

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVED.git
cd ProxmoxVED

# Run setup script (auto-detects your username from git)
bash docs/contribution/setup-fork.sh
```

That's it! ✅

---

## What Does It Do?

The `setup-fork.sh` script automatically:

1. **Detects** your GitHub username from git config
2. **Rewrites** fork-specific GitHub raw/blob links in scripts and docs to point to your fork
3. **Creates** `.git-setup-info` with recommended git workflows

---

## Usage

### Auto-Detect (Recommended)
```bash
bash docs/contribution/setup-fork.sh
```
Automatically reads your GitHub username from `git remote origin url`

### Specify Username
```bash
bash docs/contribution/setup-fork.sh john
```
Updates links to `github.com/john/ProxmoxVED`

### Custom Repository Name
```bash
bash docs/contribution/setup-fork.sh john my-fork
```
Updates links to `github.com/john/my-fork`

### Full Fork URL or `owner/repo`
```bash
bash docs/contribution/setup-fork.sh john/my-fork
bash docs/contribution/setup-fork.sh https://github.com/john/my-fork
```
Useful when you want to paste the fork directly instead of passing separate arguments.

---

## What Gets Updated?

The script scans these areas and rewrites copy/paste GitHub URLs that should point to your fork:
- `ct/`
- `install/`
- `misc/`
- `vm/`
- `tools/`
- `docs/`

It also creates `.git-setup-info` in the repository root.

---

## After Setup

1. **Review changes**
   ```bash
   git diff docs/
   ```

2. **Read git workflow tips**
   ```bash
   cat .git-setup-info
   ```

3. **Start contributing**
   ```bash
   git checkout -b feature/my-app
   # Make your changes...
   git commit -m "feat: add my awesome app"
   ```

4. **Follow the guide**
   ```bash
   cat docs/contribution/README.md
   ```

---

## Common Workflows

### Keep Your Fork Updated
```bash
# Add upstream if you haven't already
git remote add upstream https://github.com/community-scripts/ProxmoxVED.git

# Get latest from upstream
git fetch upstream
git rebase upstream/main
git push origin main
```

### Create a Feature Branch
```bash
git checkout -b feature/docker-improvements
# Make changes...
git push origin feature/docker-improvements
# Then create PR on GitHub
```

### Sync Before Contributing
```bash
git fetch upstream
git rebase upstream/main
git push -f origin main  # Update your fork's main
git checkout -b feature/my-feature
```

---

## Troubleshooting

### "Git is not installed" or "not a git repository"
```bash
# Make sure you cloned the repo first
git clone https://github.com/YOUR_USERNAME/ProxmoxVED.git
cd ProxmoxVED
bash docs/contribution/setup-fork.sh
```

### "Could not auto-detect GitHub username"
```bash
# Your git origin URL isn't set up correctly
git remote -v
# Should show your fork URL, not community-scripts

# Fix it:
git remote set-url origin https://github.com/YOUR_USERNAME/ProxmoxVED.git
bash docs/contribution/setup-fork.sh
```

### "Permission denied"
```bash
# Make script executable
chmod +x docs/contribution/setup-fork.sh
bash docs/contribution/setup-fork.sh
```

### Need to Change the Target Fork?
```bash
# Re-run the script with the correct values
bash docs/contribution/setup-fork.sh YOUR_USERNAME
# Or pass the full fork URL
bash docs/contribution/setup-fork.sh https://github.com/YOUR_USERNAME/ProxmoxVED
```

---

## Next Steps

1. ✅ Run `bash docs/contribution/setup-fork.sh`
2. 📖 Read [docs/contribution/README.md](README.md)
3. 🍴 Choose your contribution path:
   - **Containers** → [docs/ct/README.md](docs/ct/README.md)
   - **Installation** → [docs/install/README.md](docs/install/README.md)
   - **VMs** → [docs/vm/README.md](docs/vm/README.md)
   - **Tools** → [docs/tools/README.md](docs/tools/README.md)
4. 💻 Create your feature branch and contribute!

---

## Questions?

- **Fork Setup Issues?** → See [Troubleshooting](#troubleshooting) above
- **How to Contribute?** → [docs/contribution/README.md](README.md)
- **Git Workflows?** → `cat .git-setup-info`
- **Project Structure?** → [docs/README.md](docs/README.md)

---

**Happy Contributing! 🚀**
