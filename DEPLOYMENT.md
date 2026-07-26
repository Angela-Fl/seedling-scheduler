# Deployment Guide – Seedling Scheduler

This document explains how the **Seedling Scheduler** Rails application is deployed to production, including important configuration decisions, known pitfalls, and how to redeploy safely.

---

## Overview

- **Platform:** Fly.io (Machines)
- **Framework:** Ruby on Rails (Rails 8)
- **Web server:** Rails built-in server (no reverse proxy)
- **Containerization:** Docker
- **Database:** SQLite (persistent Fly volume)
- **HTTPS:** Terminated at Fly.io edge

The app runs as a single web process and is designed for simplicity and reliability rather than complex multi-process orchestration.

---

## High-Level Architecture

```
Internet
   ↓
Fly.io Edge (HTTPS)
   ↓
Rails server (port 8080)
   ↓
SQLite database (Fly volume)
```

Key design choice:
- **Rails listens directly on port 8080** inside the container.
- No reverse proxy (e.g., Thruster, Puma proxy layer) is used.

---

## Why This Setup

Rails 8 includes a default proxy tool called **Thruster**, which forwards requests to a Rails server on port 3000. In this app, Thruster was removed because:

- It added unnecessary complexity for a single-process app
- It caused port mismatches and failed health checks on Fly.io
- Running Rails directly is simpler and more stable for this use case

---

## Docker Configuration

The container runs Rails directly and binds explicitly to Fly’s expected interface and port.

**Key Dockerfile command:**

```dockerfile
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]
```

This ensures:
- Rails listens on all interfaces
- The port matches Fly’s `internal_port`

---

## Fly.io Configuration

### fly.toml (relevant sections)

```toml
[http_service]
internal_port = 8080
force_https = true
auto_start_machines = true
auto_stop_machines = true

[[http_service.checks]]
method = "GET"
path = "/up"
interval = "30s"
timeout = "5s"
grace_period = "10s"
```

---

## Health Check (`/up`)

Fly.io requires a health check endpoint that returns **200 OK** with no redirects.

This app defines a minimal health check route:

```ruby
get "/up", to: proc { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
```

Why this approach:
- Avoids controller overhead
- Avoids HTTPS or host-based redirects
- Does not depend on database availability
- Extremely reliable for health probes

---

## Rails Production Configuration

In `config/environments/production.rb`:

```ruby
config.assume_ssl = true
```

This tells Rails it is running behind an HTTPS-terminating proxy (Fly.io), preventing redirect loops and incorrect scheme detection.

---

## Database & Volumes

- SQLite is stored on a **persistent Fly volume** mounted at `/rails/storage`
- Migrations are run automatically during deploy via Fly’s `release_command`

```bash
./bin/rails db:migrate
```

---

## Environment Variables & Secrets

Required secrets are managed via Fly:

- `RAILS_MASTER_KEY`

Set with:

```bash
fly secrets set RAILS_MASTER_KEY=...
```

---

## Deploying the App

### Recommended deployment method (Windows + WSL users)

Due to IPv6 networking limitations in WSL2, deployments should be run from **Windows PowerShell**, accessing the WSL filesystem via `\\wsl$`.

Example:

```powershell
explorer.exe \\wsl$\Ubuntu\home\adminang\projects\seedling_scheduler
```

Open PowerShell in that directory, then:

```powershell
fly deploy --build-arg GIT_SHA=$(git rev-parse HEAD)
```

Always pass `--build-arg GIT_SHA=...`. It stamps the image with the commit it was
built from so `/version` can report it later (see *Identifying the deployed commit*
below). `$( )` is a subexpression in PowerShell just as in bash, so the same command
works from either shell. Omitting it still deploys fine, but `/version` will read
`unknown` and you lose the ability to tell what is running.

> **Note:** `fly deploy` builds whatever is in your **working directory** — not a
> branch, and not what is on GitHub. Check out the commit you intend to ship before
> deploying, and remember that uncommitted changes in the working tree go out too.

---

## Identifying the deployed commit

The app exposes a public `/version` endpoint reporting the commit its image was
built from:

```bash
curl https://seedlingscheduler.com/version
# {"git_sha":"57f543f516082911a1cbb83a4c44534e799842d3"}
```

Compare it against local history to see exactly what is live:

```bash
git log --oneline $(curl -s https://seedlingscheduler.com/version | jq -r .git_sha)..HEAD
```

An empty result means production is up to date with your current branch; anything
listed is undeployed.

**How it works:** `.dockerignore` excludes `/.git/`, so the build cannot read the
repository itself. The SHA is therefore passed in as a Docker `ARG` and promoted to
an `ENV` in the final image stage, where the running app reads it. The `ARG` is
declared at the end of the Dockerfile so a changed SHA only invalidates that last
layer, leaving the gem install and Vite asset build cached.

`unknown` in the response means the image was built without the build arg.

Fly's own metadata does **not** record a git SHA (`fly releases --json` shows
`"Metadata": null`), so without this endpoint the only way to identify a running
release is matching deploy timestamps against commit timestamps by hand.

---

## Common Pitfalls & Lessons Learned

### 1. Port mismatches
- Fly expects the app on `internal_port = 8080`
- Any proxy forwarding to `127.0.0.1:3000` will fail unless Rails is actually listening there

### 2. Health checks must not redirect
- HTTP 301/302 responses will cause Fly to mark the app unhealthy

### 3. WSL IPv6 issues
- Fly APIs may resolve to IPv6 addresses
- WSL2 often lacks IPv6 routing
- Use Windows Fly CLI for reliable deploys

### 4. Avoid unnecessary proxies
- Simpler is more stable for single-app deployments

---

## Verifying a Healthy Deployment

```bash
curl -i https://seedling-scheduler.fly.dev/
curl -i https://seedling-scheduler.fly.dev/up
fly machines list
```

Expected results:
- Homepage loads
- `/up` returns `200 OK`
- Machines show `CHECKS 1/1`

---

## Final Notes

This deployment favors:
- Clarity over cleverness
- Explicit configuration over defaults
- Stability over premature optimization

Future scaling (multiple machines, background jobs, proxies) can be added later if needed.

