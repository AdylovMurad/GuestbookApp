#!/bin/bash
source ../config.sh

cat > api-gateway.yaml << EOF
openapi: 3.0.0
info:
  title: Guestbook API
  version: 1.0.0

paths:
  /:
    get:
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${BUCKET_NAME}
        object: index.html
      responses:
        '200':
          description: OK

  /favicon.ico:
    get:
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${BUCKET_NAME}
        object: favicon.ico
      responses:
        '200':
          description: OK

  /api/messages:
    get:
      x-yc-apigateway-integration:
        type: http
        url: ${CONTAINER_URL}/api/messages
        method: GET
      responses:
        '200':
          description: OK
    post:
      x-yc-apigateway-integration:
        type: http
        url: ${CONTAINER_URL}/api/messages
        method: POST
      responses:
        '200':
          description: OK

  /api/version:
    get:
      x-yc-apigateway-integration:
        type: http
        url: ${CONTAINER_URL}/api/version
        method: GET
      responses:
        '200':
          description: OK

  /api/stats:
    get:
      x-yc-apigateway-integration:
        type: http
        url: ${CONTAINER_URL}/api/stats
        method: GET
      responses:
        '200':
          description: OK

  /{file}:
    get:
      parameters:
        - name: file
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${BUCKET_NAME}
        object: '{file}'
      responses:
        '200':
          description: OK
EOF

# Создание/обновление API Gateway
yc serverless api-gateway create \
  --name guestbook-api \
  --spec=api-gateway.yaml \
  --description "API Gateway для гостевой книги" \
  --folder-id ${FOLDER_ID}
