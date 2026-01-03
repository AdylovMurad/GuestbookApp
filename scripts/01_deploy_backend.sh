#!/bin/bash
source ../config.sh

log "Развертывание бэкенда..."

log "Построение Docker образа..."
cd ${BACKEND_DIR}

echo ${BACKEND_VERSION} > version.txt

echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USERNAME} --password-stdin cr.yandex

IMAGE_NAME="cr.yandex/${REGISTRY_ID}/${CONTAINER_NAME}:${BACKEND_VERSION