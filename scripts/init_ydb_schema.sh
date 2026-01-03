#!/bin/bash
echo "Инициализация схемы YDB..."

API_URL="d5dfhgu4kl9q539qlgup.akta928u.apigw.yandexcloud.net"

curl -X GET "https://$API_URL/health"

