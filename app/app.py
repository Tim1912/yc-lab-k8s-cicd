from flask import Flask
import os

app = Flask(__name__)

# Получаем параметры БД из переменных окружения
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_NAME = os.getenv('DB_NAME', 'app_db')
DB_USER = os.getenv('DB_USER', 'db_user')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')

@app.route('/')
def hello():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Web Application - Timur Zhukov</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: rgba(255,255,255,0.1);
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 { color: #fff; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
            .info { 
                background: rgba(255,255,255,0.2); 
                padding: 15px; 
                border-radius: 5px;
                margin: 10px 0;
            }
            .success { color: #90EE90; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>👋 Тимур Жуков</h1>
            <h2> Любимый вкус мороженого: Пломбир</h2>
            <hr>
            <h3>📊 Информация о приложении:</h3>
            <div class="info"><strong>Host:</strong> """ + DB_HOST + """</div>
            <div class="info"><strong>Database:</strong> """ + DB_NAME + """</div>
            <div class="info"><strong>User:</strong> """ + DB_USER + """</div>
            <p class="success">✅ Приложение работает! Подключение к БД настроено.</p>
        </div>
    </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)