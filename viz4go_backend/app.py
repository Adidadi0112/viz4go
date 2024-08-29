from flask import Flask
from config import get_db_connection, graph
from routes.go_routes import go_bp

app = Flask(__name__)

# Rejestracja tras z folderu routes
app.register_blueprint(go_bp, url_prefix='/api/go')

if __name__ == '__main__':
    app.run(debug=True)
