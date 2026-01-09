#!/bin/bash
source ../config.sh

NEW_VERSION="2.0.0"

sed -i "s/1\.0\.2/$NEW_VERSION/g" ${FRONTEND_DIR}/app.js
sed -i "s/1\.0\.20/$NEW_VERSION/g" ${FRONTEND_DIR}/index.html
echo $NEW_VERSION > ${FRONTEND_DIR}/version.txt

for file in index.html style.css app.js; do
    yc storage object upload \
        --bucket-name ${BUCKET_NAME} \
        --path "${FRONTEND_DIR}/$file" \
        --name "$file" \
        --force
done

echo "Updating Data Base"
API_URL="https://d5dfhgu4kl9q539qlgup.akta928u.apigw.yandexcloud.net"
curl -X POST "${API_URL}/api/versions" \
    -H "Content-Type: application/json" \
    -d "{\"component\": \"frontend\", \"version\": \"${NEW_VERSION}\"}" \
    --silent
