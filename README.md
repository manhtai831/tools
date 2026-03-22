# Docker Tools

A set of shell scripts for building, saving, and pushing Docker images with progress visualization.

- **`docker_tool`** — Build, tag, save, and optionally upload a Docker image archive.
- **`docker_push`** — Push a local image to AWS ECR, GitHub Container Registry, or a remote server via SCP.

---

## Installation

### Option 1 — Local clone

```bash
git clone https://github.com/manhtai831/tools.git
cd tools
./install.sh
```

### Option 2 — One-liner via curl

```bash
curl -fsSL https://raw.githubusercontent.com/manhtai831/tools/main/install.sh | bash
```

The installer will:

1. Copy `docker_tool` and `docker_push` to `/usr/local/bin` (requires `sudo`).
2. Copy the shell completion files to `~/.config/docker-tools/`.
3. Append a `source` hook to `~/.bashrc` and `~/.zshrc` (only once, guarded by a marker).

After installation, reload your shell:

```bash
source ~/.zshrc   # zsh
source ~/.bashrc  # bash
```

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| `docker` | Build / save images | [docs.docker.com](https://docs.docker.com/get-docker/) |
| `pv` | Progress visualization | macOS: `brew install pv` · Ubuntu: `sudo apt install pv` |
| `curl` | Upload / downloading | usually pre-installed |
| `gzip` | Compress image archives | usually pre-installed |
| `aws` CLI | ECR push *(optional)* | `brew install awscli` |
| `ssh` / `scp` | SCP push *(optional)* | usually pre-installed |

---

## docker_tool

Build a Docker image, tag it with one or more tags, save it as a `.tar.gz` archive, and optionally upload it to an HTTP API.

```
docker_tool [-i image_name] [-t tag]... [-o build_context] [-f dockerfile] [-u] [-U url]
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `-i <name>` | current directory name | Image name. Can be a comma-separated list for multiple image names. |
| `-t <tag>` | `latest` | Tag to apply. Can be repeated (`-t 1.0.0 -t stable`) or comma-separated (`-t 1.0.0,stable`). |
| `-o <dir>` | `.` | Docker build context directory. |
| `-f <path>` | `Dockerfile` | Path to the Dockerfile (absolute or relative to `-o`). |
| `-u` | off | Enable upload of the archive to an API after saving. |
| `-U <url>` | `$DOCKER_TOOL_UPLOAD_URL` | Upload API endpoint. Required when `-u` is set. Can also be set via the environment variable `DOCKER_TOOL_UPLOAD_URL`. |
| `-h` | — | Show help. |

### Workflow

The script runs five steps:

1. `docker build` — builds the image with a timestamped `build-<timestamp>` tag.
2. `docker tag` — applies every tag specified with `-t` (plus a short git commit ID if inside a git repo).
3. `docker image save | pv | gzip` — streams the image through `pv` (with a +10 % size estimate for TAR overhead) and compresses it to `<image>_<primary_tag>.tar.gz`.
4. `curl` upload — posts the archive to the configured API (only when `-u` is given).
5. Filename extraction — parses the `"filename"` field from the JSON response and prints the download URL.

### Examples

```bash
# Build using defaults (image name = current dir, tag = latest)
docker_tool

# Build with explicit name and tags
docker_tool -i myapp -t 1.0.0 -t stable -o . -f Dockerfile

# Build and upload
docker_tool -i myapp -t 1.0.0 -u -U https://files.example.com/api/upload

# Use environment variable for upload URL
export DOCKER_TOOL_UPLOAD_URL=https://files.example.com/api/upload
docker_tool -i myapp -t 1.0.0 -u
```

---

## docker_push

Push an existing local Docker image to a remote registry or server.

```
docker_push -m <method> -i <image_ref> [options]
```

### Methods

| Method | Target |
|--------|--------|
| `aws` | AWS Elastic Container Registry (ECR) |
| `ghcr` | GitHub Container Registry (`ghcr.io`) |
| `scp` | Remote server via SCP (copies the `.tar.gz` archive) |

### Common options

| Flag | Description |
|------|-------------|
| `-m <method>` | Push method: `aws`, `ghcr`, or `scp`. **Required.** |
| `-i <image_ref>` | Full image reference including tag (see format per method below). **Required.** |
| `-h` | Show help. |

### AWS ECR options

```
docker_push -m aws -i <registry>/<repo>:<tag> [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-R <region>` | inferred from registry URL, or `$AWS_DEFAULT_REGION` | AWS region. |
| `-A <key_id>` | `$AWS_ACCESS_KEY_ID` | AWS access key ID. |
| `-S <secret>` | `$AWS_SECRET_ACCESS_KEY` | AWS secret access key. |

The script calls `aws ecr get-login-password` and pipes it to `docker login`, then runs `docker push`. Credentials are unset from the environment after the push.

```bash
# Using environment credentials
docker_push -m aws -i 123456789.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:latest

# Providing credentials inline
docker_push -m aws \
  -i 123456789.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:latest \
  -A AKIAIOSFODNN7EXAMPLE \
  -S wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### GitHub Container Registry (GHCR) options

```
docker_push -m ghcr -i ghcr.io/<user>/<repo>:<tag> [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-g <user>` | `$GHCR_USER` | GitHub username. |
| `-k <token>` | `$GHCR_TOKEN` | GitHub personal access token (needs `write:packages` scope). |

```bash
docker_push -m ghcr -i ghcr.io/myuser/myapp:1.0.0 -g myuser -k ghp_xxxxxxxxxxxx
```

### SCP options

```
docker_push -m scp -i <image_name>:<tag> -H <host> [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-H <host>` | — | Remote hostname or IP. **Required.** |
| `-U <user>` | current user | Remote SSH username. |
| `-p <path>` | `~` | Remote destination directory. Created automatically if it does not exist. |
| `-P <port>` | `22` | SSH port. |
| `-K <key>` | — | Path to SSH private key. |

If the `.tar.gz` archive from a previous `docker_tool` run already exists in the current directory it will be reused; otherwise the image is saved automatically before transfer.

```bash
docker_push -m scp \
  -i myapp:latest \
  -H 192.168.1.10 \
  -U ubuntu \
  -p /opt/images \
  -K ~/.ssh/id_rsa
```

---

## Environment variables

| Variable | Used by | Description |
|----------|---------|-------------|
| `DOCKER_TOOL_UPLOAD_URL` | `docker_tool` | Default upload API URL (overridden by `-U`). |
| `GHCR_USER` | `docker_push` | GitHub username. |
| `GHCR_TOKEN` | `docker_push` | GitHub personal access token. |
| `AWS_ACCESS_KEY_ID` | `docker_push` | AWS access key ID. |
| `AWS_SECRET_ACCESS_KEY` | `docker_push` | AWS secret access key. |
| `AWS_DEFAULT_REGION` | `docker_push` | Default AWS region. |
| `AWS_PROFILE` | `docker_push` | AWS CLI named profile. |
