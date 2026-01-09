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
BACKEND_VERSION = os.getenv('BACKEND_VERSION', '1.0.3')
CONTAINER_ID = os.getenv('CONTAINER_ID', 'unknown')

def init_ydb():
    try:
        driver_config = ydb.DriverConfig(
            endpoint=YDB_ENDPOINT,
            database=YDB_DATABASE,
            credentials=ydb.iam.MetadataUrlCredentials(),
        )
        driver = ydb.Driver(driver_config)
        driver.wait(fail_fast=True, timeout=5)
        pool = ydb.SessionPool(driver)
        return driver, pool
    except Exception as e:
        print(f"YDB connection error: {str(e)}")
        return None, None

def execute_query(query, params={}):
    driver, pool = init_ydb()
    if driver is None or pool is None:
        raise Exception("YDB not available")
    
    try:
        def callee(session):
            prepared = session.prepare(query)
            return session.transaction().execute(
                prepared,
                params,
                commit_tx=True
            )
        result = pool.retry_operation_sync(callee)
        return result
    except Exception as e:
        print(f"Query error: {str(e)}")
        raise
    finally:
        if driver:
            try:
                driver.stop(timeout=1)
            except:
                pass

def get_total_messages_count():
    try:
        query = '''
        SELECT COUNT(*) as total_count
        FROM guestbook_messages
        '''
        result = execute_query(query)
        
        if result and result[0].rows:
            return result[0].rows[0].total_count
        return 0
    except Exception as e:
        print(f"Error counting messages: {str(e)}")
        return 0

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "version": BACKEND_VERSION})

@app.route('/')
def index():
    return jsonify({"service": "Guestbook API", "version": BACKEND_VERSION})

@app.route('/api/version', methods=['GET'])
def get_version():
    return jsonify({
        "backend": BACKEND_VERSION,
        "container": CONTAINER_ID
    })

@app.route('/api/messages', methods=['GET'])
def get_messages():
    try:
        query = '''
        SELECT id, author, message, created_at
        FROM guestbook_messages
        ORDER BY created_at DESC
        LIMIT 100
        '''
        result = execute_query(query)
        messages = []
        
        for row in result[0].rows:
            created_at_str = None
            if row.created_at:
                try:
                    ts_seconds = row.created_at / 1000000
                    dt = datetime.fromtimestamp(ts_seconds)
                    created_at_str = dt.isoformat()
                except:
                    created_at_str = str(row.created_at)
            
            messages.append({
                "id": row.id.decode('utf-8') if isinstance(row.id, bytes) else row.id,
                "author": row.author.decode('utf-8') if row.author and isinstance(row.author, bytes) else (row.author or "Аноним"),
                "message": row.message.decode('utf-8') if row.message and isinstance(row.message, bytes) else row.message,
                "created_at": created_at_str
            })
        
        return jsonify(messages)
    except Exception as e:
        print(f"Error getting messages: {e}")
        return jsonify([])

@app.route('/api/messages', methods=['POST'])
def add_message():
    try:
        data = request.get_json(force=True) 
        
        if not data or 'message' not in data:
            return jsonify({"error": "Message is required"}), 400
        
        message_id = str(uuid.uuid4())
        author = data.get('author', 'Аноним')
        message = data['message']
        
        query = '''
        DECLARE $id AS Utf8;
        DECLARE $author AS Utf8;
        DECLARE $message AS Utf8;
        
        UPSERT INTO guestbook_messages (id, author, message, created_at)
        VALUES ($id, $author, $message, CurrentUtcTimestamp());
        '''
        
        params = {
            '$id': message_id,
            '$author': author,
            '$message': message
        }
        
        execute_query(query, params)
        
        return jsonify({
            "id": message_id,
            "status": "created",
            "container_id": CONTAINER_ID
        })
    except Exception as e:
        print(f"Error in add_message: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    try:
        total_messages = get_total_messages_count()
        
        return jsonify({
            "total_messages": total_messages,
            "backend_version": BACKEND_VERSION,
            "frontend_version": "1.0.3"
        })
    except Exception as e:
        print(f"Error getting stats: {str(e)}")
        return jsonify({
            "total_messages": 0,
            "backend_version": BACKEND_VERSION,
            "frontend_version": "1.0.3"
        })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)