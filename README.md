# Tony Teaches Tech VPS Scripts

Reusable VPS setup scripts used in my Tony Teaches Tech YouTube tutorials.

These scripts are designed to help beginners prepare fresh Ubuntu or Debian servers for self-hosting, Docker deployments, and general server administration.

## Available Scripts

| Script            | Purpose                                                              |
| ----------------- | -------------------------------------------------------------------- |
| `setup-docker.sh` | Prepares a fresh Ubuntu or Debian VPS for Docker-based self-hosting. |

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

## What It Does Not Do

This script is meant to be a fast baseline setup, not a perfect replacement for the full manual tutorial.

It does **not**:

* Create a swap file
* Generate or copy your SSH key
* Fully disable password-based SSH login
* Fully disable every possible root SSH login method

For the full manual walkthrough, including swap setup and stricter SSH key-only authentication, read the full guide:

[How to Set Up an Ubuntu VPS for Self-Hosting Docker Apps](https://tonyteaches.tech/ubuntu-vps-docker-self-hosting/)

## Quick Start

Run this on a fresh Ubuntu or Debian VPS:

```bash
wget https://raw.githubusercontent.com/tonyflo/ttt-vps-scripts/main/setup-docker.sh
chmod +x setup-docker.sh
sudo ./setup-docker.sh
```

## After the Script Finishes

When the script completes, log out of the root session and reconnect as the new user created by the script:

```bash
ssh your_username@your_server_ip
```

Docker group permissions do not apply until you log out and back in.

To confirm Docker is working:

```bash
docker run hello-world
```

## Recommended Next Steps

After running the script, I recommend following the manual guide to:

* Add a swap file if your VPS has limited RAM
* Set up SSH key authentication
* Disable password-based SSH login

Full guide:

[How to Set Up an Ubuntu VPS for Self-Hosting Docker Apps](https://tonyteaches.tech/ubuntu-vps-docker-self-hosting/)

## Notes

These scripts are intended for fresh Ubuntu or Debian servers that use `apt` and `systemd`.
