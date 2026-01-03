#!/bin/bash

if [ -f "../config.sh" ]; then
    source ../config.sh
else
    exit 1
fi

yc iam service-account create ${SERVICE_ACCOUNT_NAME} \
    --folder-id ${FOLDER_ID} \
    --description "Service Account для гостевой книги"

SA_ID=$(yc iam service-account get ${SERVICE_ACCOUNT_NAME} --format json | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "SA ID: $SA_ID"

if [ -z "$SA_ID" ]; then
    echo "ОШИБКА: Не удалось получить ID Service Account"
    exit 1
fi

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

echo "4. Создание Yandex Database..."
yc ydb database create ${YDB_NAME} \
    --serverless \
    --description "База данных для гостевой книги" \
    --folder-id ${FOLDER_ID}

yc ydb database get ${YDB_NAME} --format json > ydb_info.json

YDB_ENDPOINT=$(grep -o '"endpoint":"[^"]*"' ydb_info.json | cut -d'"' -f4)
YDB_DATABASE=$(grep -o '"database_path":"[^"]*"' ydb_info.json | cut -d'"' -f4)

echo "YDB Endpoint: $YDB_ENDPOINT"
echo "YDB Database: $YDB_DATABASE"

echo "export YDB_ENDPOINT='$YDB_ENDPOINT'" >> ../config.sh
echo "export YDB_DATABASE='$YDB_DATABASE'" >> ../config.sh

yc container registry create ${CONTAINER_REGISTRY_NAME} \
    --folder-id ${FOLDER_ID}

yc iam access-key create --service-account-name ${SERVICE_ACCOUNT_NAME} --format json > ../docker-key.json

DOCKER_USERNAME=$(grep -o '"key_id":"[^"]*"' ../docker-key.json | cut -d'"' -f4)
DOCKER_PASSWORD=$(grep -o '"secret":"[^"]*"' ../docker-key.json | cut -d'"' -f4)

echo "export DOCKER_REGISTRY='cr.yandex'" >> ../config.sh
echo "export DOCKER_USERNAME='$DOCKER_USERNAME'" >> ../config.sh
echo "export DOCKER_PASSWORD='$DOCKER_PASSWORD'" >> ../config.sh

echo ""
echo "СОХРАНЕННЫЕ ДАННЫЕ:"
echo "1. Service Account ID: $SA_ID"
echo "2. YDB Endpoint: $YDB_ENDPOINT"
echo "3. YDB Database: $YDB_DATABASE"
echo "4. Docker Username: $DOCKER_USERNAME"
echo "5. Docker Password: $DOCKER_PASSWORD"
echo ""
echo "Файлы созданы:"
echo "- docker-key.json (ключи для Docker)"
echo "- ydb_info.json (информация о YDB)"
echo "- config.sh обновлен"