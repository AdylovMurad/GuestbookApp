import os
import json
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
import ydb
import ydb.iam

app = Flask(__name__)

YDB_ENDPOINT = os.getenv('YDB_ENDPOINT', 'grpcs://ydb.serverless.yandexcloud.net:2135')
YDB_DATABASE = os.getenv('YDB_DATABASE', '')
BACKEND_VERSION = os.getenv('BACKEND_VERSION', '1.0.0')
CONTAINER_ID = os.getenv('CONTAINER_ID', 'unknown')

def init_driver():
    driver_config = ydb.DriverConfig(
        endpoint=YDB_ENDPOINT,
        database=YDB_DATABASE,
        credentials=ydb.iam.MetadataUrlCredentials(),
    )
    return ydb.Driver(driver_config)

driver = init_driver()
driver.wait(fail_fast=True, timeout=5)
pool = ydb.SessionPool(driver)

def execute_query(query, params={}):
    def callee(session):
        prepared = session.prepare(query)
        return session.transaction().execute(
            prepared,
            params,
            commit_tx=True
        )
    return pool.retry_operation_sync(callee)

def init_database():
    create_table_query = '''
    CREATE TABLE IF NOT EXISTS guestbook_messages (
        id Text NOT NULL,
        author Text,
        message Text,
        created_at Timestamp,
        PRIMARY KEY (id)
    );
    
    CREATE TABLE IF NOT EXISTS app_versions (
        component Text NOT NULL,
        version Text,
        updated_at Timestamp,
        PRIMARY KEY (component)
    );
    
    UPSERT INTO app_versions (component, version, updated_at)
    SELECT 'backend', '{0}', CurrentUtcTimestamp()
    WHERE NOT EXISTS (
        SELECT 1 FROM app_versions WHERE component = 'backend'
    );
    '''.format(BACKEND_VERSION)
    
    try:
        execute_query(create_table_query)
        print("Database initialized successfully")
    except Exception as e:
        print(f"Database init error: {e}")

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "healthy",
        "backend_version": BACKEND_VERSION,
        "container_id": CONTAINER_ID,
        "ydb_connected": driver is not None
    })

@app.route('/api/version', methods=['GET'])
def get_version():
    return jsonify({
        "backend": BACKEND_VERSION,
        "container": CONTAINER_ID
    })

@app.route('/api/messages', methods=['GET'])
def get_messages():
    query = '''
    SELECT * FROM guestbook_messages 
    ORDER BY created_at DESC 
    LIMIT 100
    '''
    
    try:
        result = execute_query(query)
        messages = []
        for row in result[0].rows:
            messages.append({
                "id": row.id.decode('utf-8'),
                "author": row.author.decode('utf-8') if row.author else "Аноним",
                "message": row.message.decode('utf-8'),
                "created_at": row.created_at.ToDatetime().isoformat()
            })
        return jsonify(messages)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/messages', methods=['POST'])
def add_message():
    data = request.json
    if not data or 'message' not in data:
        return jsonify({"error": "Message is required"}), 400
    
    message_id = str(uuid.uuid4())
    author = data.get('author', 'Аноним')
    message = data['message']
    
    query = '''
    UPSERT INTO guestbook_messages (id, author, message, created_at)
    VALUES ($id, $author, $message, CurrentUtcTimestamp())
    '''
    
    params = {
        '$id': message_id,
        '$author': author,
        '$message': message
    }
    
    try:
        execute_query(query, params)

        update_stats_query = '''
        UPSERT INTO app_stats (key, value) VALUES
        ('total_messages', COALESCE(
            (SELECT value FROM app_stats WHERE key = 'total_messages'), 0
        ) + 1)
        '''
        execute_query(update_stats_query)
        
        return jsonify({
            "id": message_id,
            "status": "created",
            "container_id": CONTAINER_ID
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    query = '''
    SELECT 
        (SELECT COUNT(*) FROM guestbook_messages) as total_messages,
        (SELECT version FROM app_versions WHERE component = 'backend') as backend_version,
        (SELECT version FROM app_versions WHERE component = 'frontend') as frontend_version
    '''
    
    try:
        result = execute_query(query)
        if result[0].rows:
            row = result[0].rows[0]
            return jsonify({
                "total_messages": row.total_messages,
                "backend_version": row.backend_version.decode('utf-8') if row.backend_version else BACKEND_VERSION,
                "frontend_version": row.frontend_version.decode('utf-8') if row.frontend_version else "1.0.0"
            })
        return jsonify({
            "total_messages": 0,
            "backend_version": BACKEND_VERSION,
            "frontend_version": "1.0.0"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    init_database()
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)