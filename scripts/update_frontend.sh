#!/bin/bash
echo "Обновление фронтенда в Object Storage..."

BUCKET_NAME="guestbook-frontend-murad"
NEW_VERSION="1.1.0"

sed -i "s/Версия фронтенда:.*<\/span>/Версия фронтенда: $NEW_VERSION<\/span>/" frontend/index.html

echo "Обновлено до версии $NEW_VERSION"
echo "Фронтенд: https://${BUCKET_NAME}.website.yandexcloud.net"