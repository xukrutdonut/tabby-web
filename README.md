# Tabby Web

## Note on project status

> [!IMPORTANT]  
> At this time I don't have the time to work on `tabby-web` and won't be able to provide help or support for it. I'm still happy to merge any fixes/improvement PRs. :v:


![](docs/screenshot.png)

This is the Tabby terminal, served as a web app. It also provides the config sync service for the Tabby app.

# How it works

Tabby Web serves the [Tabby Terminal](https://github.com/Eugeny/tabby) as a web application while managing multiple config files, authentication, and providing TCP connections via a [separate gateway service](https://github.com/Eugeny/tabby-connection-gateway).

# Requirements

* Python 3.7+
* A database server supported by Django (MariaDB, Postgres, SQLite, etc.)
* Storage for distribution files - local, S3, GCS or others supported by `fsspec`

# Quickstart (using `docker-compose`)

You'll need:

* OAuth credentials from GitHub, GitLab, Google or Microsoft for authentication.
* For SSH and Telnet: a [`tabby-connection-gateway`](https://github.com/Eugeny/tabby-connection-gateway) to forward traffic.
* Docker BuildKit: `export DOCKER_BUILDKIT=1`

## Basic Setup

1. Copy the environment file and configure it:
```bash
cp .env.example .env
nano .env  # Edit with your OAuth credentials and settings
```

2. Start the services:
```bash
export DOCKER_BUILDKIT=1
docker-compose up -d
```

This will start Tabby Web on port 9090 with MariaDB as a storage backend.

For SSH and Telnet, once logged in, enter your connection gateway address and auth token in the settings.

## Raspberry Pi 5 Installation

For detailed instructions on installing Tabby Web on Raspberry Pi 5 with Docker behind Nginx Proxy Manager:

- **Quick Start**: [QUICKSTART_RPI5.md](QUICKSTART_RPI5.md) - Get started in 5 minutes
- **Complete Guide**: [INSTALL_RPI5.md](INSTALL_RPI5.md) - Full installation and configuration
- **Nginx Config**: [NGINX_PROXY_MANAGER_CONFIG.md](NGINX_PROXY_MANAGER_CONFIG.md) - Proxy setup guide
- **Deployment Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Step-by-step verification list

## Environment variables

* `DATABASE_URL` (required).
* `APP_DIST_STORAGE`: a `file://`, `s3://`, or `gcs://` URL to store app distros in.
* `SOCIAL_AUTH_*_KEY` & `SOCIAL_AUTH_*_SECRET`: social login credentials, supported providers are `GITHUB`, `GITLAB`, `MICROSOFT_GRAPH` and `GOOGLE_OAUTH2`.

## Adding Tabby app versions

* `docker-compose run tabby /manage.sh add_version 1.0.163`

You can find the available version numbers [here](https://www.npmjs.com/package/tabby-web-container).

# Development setup

Put your environment vars (`DATABASE_URL`, etc.) in the `.env` file in the root of the repo.

For the frontend:

```shell
cd frontend
yarn
yarn run build # or yarn run watch
```

For the backend:

```shell
cd backend
poetry install
./manage.py migrate # set up the database
./manage.py add_version 1.0.156-nightly.2 # install an app distribution
PORT=9000 poetry run gunicorn # optionally with --reload
```

# Security

* When using Tabby Web for SSH/Telnet connectivity, your traffic will pass through a hosted gateway service. It's encrypted in transit (HTTPS) and the gateway servers authenticate themselves with a certificate before connections are made. However there's a non-zero risk of a MITM if a gateway service is compromised and the attacker gains access to the service's private key.
* You can alleviate this risk by [hosting your own gateway service](https://github.com/Eugeny/tabby-connection-gateway), or your own copy of Tabby Web altogether.
