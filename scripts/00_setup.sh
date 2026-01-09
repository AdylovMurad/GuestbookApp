#!/bin/bash

source ../config.sh

yc iam service-account create ${SERVICE_ACCOUNT_NAME} \
    --folder-id ${FOLDER_ID}

SA_ID=$(yc iam service-account get ${SERVICE_ACCOUNT_NAME} --format json | jq -r '.id')

yc resource-manager folder add-access-binding ${FOLDER_ID} \
    --role editor \
    --subject serviceAccount:${SA_ID}

yc resource-manager folder add-access-binding ${FOLDER_ID} \
    --role serverless.containers.invoker \
    --subject serviceAccount:${SA_ID}

yc resource-manager folder add-access-binding ${FOLDER_ID} \
    --role storage.uploader \
    --subject serviceAccount:${SA_ID}

yc resource-manager folder add-access-binding ${FOLDER_ID} \
    --role ydb.editor \
    --subject serviceAccount:${SA_ID}


yc ydb database create ${YDB_NAME} \
    --serverless \
    --folder-id ${FOLDER_ID}

YDB_INFO=$(yc ydb database get ${YDB_NAME} --format json)
export YDB_ENDPOINT=$(echo ${YDB_INFO} | jq -r '.endpoint')
export YDB_DATABASE=$(echo ${YDB_INFO} | jq -r '.database_path')

echo "YDB_ENDPOINT=${YDB_ENDPOINT}" >> ../config.sh
echo "YDB_DATABASE=${YDB_DATABASE}" >> ../config.sh

yc container registry create ${CONTAINER_REGISTRY_NAME} \
    --folder-id ${FOLDER_ID}

REGISTRY_ID=$(yc container registry get ${CONTAINER_REGISTRY_NAME} --format json | jq -r '.id')

yc iam access-key create --service-account-name ${SERVICE_ACCOUNT_NAME} > ../docker-key.json

export DOCKER_USERNAME=$(cat ../docker-key.json | jq -r '.access_key.key_id')
export DOCKER_PASSWORD=$(cat ../docker-key.json | jq -r '.secret')

echo "DOCKER_REGISTRY=cr.yandex" >> ../config.sh
echo "DOCKER_USERNAME=${DOCKER_USERNAME}" >> ../config.sh
echo "DOCKER_PASSWORD=${DOCKER_PASSWORD}" >> ../config.sh


log "YDB Endpoint: ${YDB_ENDPOINT}"
log "YDB Database: ${YDB_DATABASE}"
log "Registry ID: ${REGISTRY_ID}"