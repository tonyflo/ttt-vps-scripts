# Ghost Website Stack

A starter Docker Compose stack for running:

- Ghost on the primary domain
- Matomo on `analytics.example.com`
- Uptime Kuma on `status.example.com`
- Kutt on `go.example.com`

Before starting, make sure your DNS records point to the VPS and ports `80` and `443` are open.

Copy `.env.example` to `.env`, update the domains and secrets, then start the stack:

```bash
cp .env.example .env
nano .env
docker compose config
docker compose pull
docker compose up -d
