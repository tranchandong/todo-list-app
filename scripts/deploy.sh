#!/usr/bin/env bash
set -euo pipefail

export IMAGE_TAG="${1:?Missing image tag}"

if [[ ! "$IMAGE_TAG" =~ ^(jenkins-)?[0-9a-f]{40}$ ]]; then
  echo "Invalid image tag"
  exit 1
fi

cd /opt/todo-app

# Only one deployment can update containers at a time.
exec 9>/opt/todo-app/.deploy.lock
flock -w 600 9

COMPOSE_FILE="/opt/todo-app/releases/$IMAGE_TAG/docker-compose.prod.yml"

compose() {
  docker compose \
    -p todo-app \
    --project-directory /opt/todo-app \
    -f "$COMPOSE_FILE" "$@"
}

compose config --quiet
compose pull todo-backend todo-frontend

compose up -d --no-deps --force-recreate \
  todo-backend todo-frontend

curl --fail --silent --show-error \
  --retry 12 --retry-delay 5 --retry-all-errors \
  --connect-timeout 5 --max-time 10 \
  http://127.0.0.1:8080/ > /dev/null

cp "$COMPOSE_FILE" /opt/todo-app/docker-compose.prod.yml
printf 'IMAGE_TAG=%s\n' "$IMAGE_TAG" > /opt/todo-app/deployed.env

compose ps
echo "Deployed: $IMAGE_TAG"