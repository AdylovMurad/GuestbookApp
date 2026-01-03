#!/bin/bash
echo "Обновление Serverless Container..."

VERSION="2.0.0"
docker build -t guestbook-backend:$VERSION ./backend

docker tag guestbook-backend:$VERSION cr.yandex/crp5ce6eu8jqgtdgin7s/guestbook-backend:$VERSION
docker push cr.yandex/crp5ce6eu8jqgtdgin7s/guestbook-backend:$VERSION

yc serverless container revision deploy \
  --container-name guestbook-backend \
  --image cr.yandex/crp5ce6eu8jqgtdgin7s/guestbook-backend:$VERSION \
  --cores 1 \
  --memory 1GB \
  --concurrency 4 \
  --service-account-id ajea3jl0iqs1ra81b9a6 \
  --environment "YDB_ENDPOINT=grpcs://ydb.serverless.yandexcloud.net:2135,YDB_DATABASE=/ru-central1/b1gs4v0spf3gqtfk0dlj/etnl0edkqt1ufa0ajp5i,BACKEND_VERSION=$VERSION"

echo "Бэкенд обновлен до версии $VERSION"