# Tony Teaches Tech VPS Scripts

Reusable VPS setup scripts and Docker Compose stacks used in my Tony Teaches Tech YouTube tutorials.

These resources are designed to help beginners prepare fresh Ubuntu or Debian servers for self-hosting, Docker deployments, and general server administration.

## Available Scripts

| Script                               | Purpose                                                              |
| ------------------------------------ | -------------------------------------------------------------------- |
| [`setup-docker.sh`](setup-docker.sh) | Prepares a fresh Ubuntu or Debian VPS for Docker-based self-hosting. |

## Available Stacks

| Stack                                                | Purpose                                                 |
| ---------------------------------------------------- | ------------------------------------------------------- |
| [`ghost-website-stack`](stacks/ghost-website-stack/) | Runs Ghost, Matomo, Uptime Kuma, and Kutt behind Caddy. |

Each stack includes its own README with setup instructions.

## Docker VPS Bootstrap Script

The Docker VPS Bootstrap Script prepares a fresh VPS with a safer baseline configuration for Docker deployments.

It automates many of the first steps you should usually perform before deploying apps like WordPress, Ghost, Vaultwarden, Nextcloud, and other self-hosted services.

## What It Does

* Creates a new non-root user
* Adds the new user to the `sudo` group
* Applies basic SSH hardening
* Updates system packages
* Installs core utilities, including `htop`
* Enables unattended security updates
* Installs and starts Fail2Ban
* Configures UFW firewall rules
* Installs Docker
* Adds the new user to the `docker` group

## Quick Start

Run this as `root` on a fresh Ubuntu or Debian VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/tonyflo/ttt-vps-scripts/main/setup-docker.sh | bash
```

## After the Script Finishes

After running the script, to confirm Docker is working:

```bash
docker run --rm hello-world
```

I recommend following the manual guide to:

* Add a swap file if your VPS has limited RAM
* Set up SSH key authentication
* Disable password-based SSH login

Full guide:

[How to Set Up an Ubuntu VPS for Self-Hosting Docker Apps](https://tonyteaches.tech/ubuntu-vps-docker-self-hosting/)
