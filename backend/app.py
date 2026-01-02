import json
import os

def handler(event, context):
    """Тестовая функция для проверки"""
    backend_version = os.getenv('BACKEND_VERSION', 'backend-v1.0')
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Hello from Serverless Function!',
            'backend_version': backend_version,
            'method': event.get('httpMethod', 'GET')
        })
    }