# Changelog

## v1.6 - 2026-10-03

- Install Docker Engine from Docker's official apt repository instead of the convenience installer.
- Install the official Docker Compose and Buildx plugins.
- Detect Ubuntu and Debian automatically when configuring Docker's repository.
- Remove conflicting distro-provided Docker packages before installation when necessary.
- Verify Docker Compose before the setup is considered complete.
- Keep terminal status messages short enough to avoid unnecessary line wrapping.
- Tested successfully on a fresh Ubuntu 24.04.5 LTS VPS with Docker 29.8.2 and Docker Compose v5.6.0.

## v1.0

- Initial public release.
