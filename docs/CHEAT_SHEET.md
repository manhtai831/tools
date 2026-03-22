# Cheat Sheet — docker_tool & docker_push

Copy a command, replace the UPPERCASE placeholders, and run.

---

## docker_tool

```bash
docker_tool \
  -i IMAGE_NAME:TAG \
  -i IMAGE_NAME:TAG2 \
  -o BUILD_CONTEXT_DIR \
  -f Dockerfile \
  -u \
  -U https://UPLOAD_API_URL/api/upload
```

> `-i` can be repeated for multiple tags. `-u` and `-U` can be omitted if upload is not needed.

---

## docker_push

### Push to AWS ECR (credentials from env / aws configure)
```bash
docker_push \
  -m aws \
  -i AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/IMAGE_NAME:TAG
```

### Push to AWS ECR (inline credentials)
```bash
docker_push \
  -m aws \
  -i AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/IMAGE_NAME:TAG \
  -A AWS_ACCESS_KEY_ID \
  -S AWS_SECRET_ACCESS_KEY \
  -R AWS_REGION
```

### Push to GitHub Container Registry (GHCR)
```bash
docker_push \
  -m ghcr \
  -i ghcr.io/GITHUB_USER/IMAGE_NAME:TAG \
  -g GITHUB_USER \
  -k GITHUB_TOKEN
```

### Push to remote server via SCP
```bash
docker_push \
  -m scp \
  -i IMAGE_NAME:TAG \
  -H REMOTE_HOST \
  -U REMOTE_USER \
  -p /REMOTE/PATH \
  -K ~/.ssh/id_rsa \
  -P 22
```

---

## Full workflow: build → push to ECR

```bash
# 1. Build and tag with ECR image name directly
docker_tool \
  -i AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/IMAGE_NAME:latest \
  -o . \
  -f Dockerfile

# 2. Push to ECR
docker_push \
  -m aws \
  -i AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/IMAGE_NAME:latest
```

## Full workflow: build → push to server

```bash
# 1. Build and tag
docker_tool \
  -i IMAGE_NAME:latest \
  -o . \
  -f Dockerfile

# 2. Upload to server (reuses existing .tar.gz archive)
docker_push \
  -m scp \
  -i IMAGE_NAME:latest \
  -H REMOTE_HOST \
  -U REMOTE_USER \
  -p /REMOTE/PATH \
  -K ~/.ssh/id_rsa
```
