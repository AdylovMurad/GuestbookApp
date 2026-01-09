#!/bin/bash
source ../config.sh

cd ${BACKEND_DIR}

echo ${BACKEND_VERSION} > version.txt

echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USERNAME} --password-stdin cr.yandex


docker build -t cr.yandex/${REGISTRY_ID}/${CONTAINER_NAME}:${BACKEND_VERSION} .
docker push cr.yandex/${REGISTRY_ID}/${CONTAINER_NAME}:${BACKEND_VERSION}


yc serverless container revision deploy \
  --container-name ${CONTAINER_NAME} \
  --image cr.yandex/${REGISTRY_ID}/${CONTAINER_NAME}:${BACKEND_VERSION} \
  --cores 1 \
  --memory 1GB \
  --concurrency 8 \
  --service-account-id ${SA_ID} \
  --environment "YDB_ENDPOINT=${YDB_ENDPOINT},YDB_DATABASE=${YDB_DATABASE},BACKEND_VERSION=${BACKEND_VERSION}"