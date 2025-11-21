from flask import Flask
from routes.go_routes import go_bp
from routes.cluster_routes import cluster_bp
from flask_cors import CORS, cross_origin
from data_store import init_store

app = Flask(__name__)
CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'
init_store("go")

# Rejestracja tras z folderu routes
app.register_blueprint(go_bp, url_prefix='/api/go')
app.register_blueprint(cluster_bp, url_prefix="/api/cluster")

if __name__ == '__main__':
    app.run(debug=True)
