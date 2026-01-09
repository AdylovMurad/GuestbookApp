#!/bin/bash
# init_ydb_schema.sh - Создание и инициализация схемы YDB

source ../config.sh

echo "YDB Endpoint: $YDB_ENDPOINT"
echo "YDB Database: $YDB_DATABASE"

if ! command -v ydb &> /dev/null; then
    curl -sSL https://storage.yandexcloud.net/yandexcloud-ydb/install.sh | bash
    source ~/.bashrc
fi

if [ -f "init_db.sql" ]; then
    ydb -e $YDB_ENDPOINT -d $YDB_DATABASE scripting yql -f init_db.sql
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "YDB schema successfully created/verified"
    else
        echo "Error creating schema"
        exit 1
    fi
else
    echo "File init_db.sql not found"
    exit 1
fi

echo "Checking"
ydb -e $YDB_ENDPOINT -d $YDB_DATABASE scheme ls

echo "1. Table guestbook_messages:"
ydb -e $YDB_ENDPOINT -d $YDB_DATABASE table read guestbook_messages --limit 3

echo -e "\n2. Table app_versions:"
ydb -e $YDB_ENDPOINT -d $YDB_DATABASE table read app_versions

echo -e "\n3. Table app_stats:"
ydb -e $YDB_ENDPOINT -d $YDB_DATABASE table read app_stats

echo -e "\n YDB initialization completed successfully"