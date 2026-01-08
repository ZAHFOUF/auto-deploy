# Auto Deploy Script (Multi-App)

A lightweight Bash deployment script to pull the latest code from a Git branch across multiple applications and clear Symfony production cache.

This is designed for servers hosting several Symfony/PHP apps that share a consistent deployment workflow.

---

## Features

- Deploy multiple applications in one run
- Uses an external config file (`apps.config`) for easy maintenance
- Validates that each app is a Git repository before deploying
- Pulls a specific branch from `origin`
- Clears Symfony cache directory: `var/cache/prod`
- Safe execution: stops immediately on failure (`set -e`)
