# Viz4GO

A visualization tool for Gene Ontology (GO) terms with protein analysis capabilities. This application consists of a Python Flask backend for GO ontology processing and a Flutter web frontend for interactive visualization.

## 🚀 Quick Start with Docker

The easiest way to run Viz4GO is using Docker. No need to install Python, Flutter, or any dependencies!

### Prerequisites

- Docker Desktop (version 20.10+)
- Docker Compose (version 2.0+)

### Running the Application

**Linux/macOS:**
```bash
./start.sh
```

**Windows:**
```bash
start.bat
```

Or manually:
```bash
docker-compose up --build
```

### Access the Application

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:5000

### Stopping the Application

Press `Ctrl+C` or run:
```bash
docker-compose down
```

## 📁 Project Structure

```
viz4go/
├── viz4go_backend/          # Python Flask backend
│   ├── app.py              # Main Flask application
│   ├── data_store.py       # GO ontology data management
│   ├── similarity.py       # GO term similarity measures
│   ├── utils.py            # Utility functions
│   ├── routes/             # API endpoints
│   ├── _resources/         # GO ontology files
│   └── data/               # Application data
│
├── viz4go_frontend/         # Flutter web frontend
│   ├── lib/                # Dart source code
│   ├── web/                # Web-specific files
│   └── assets/             # Static assets
│
├── docker-compose.yml       # Docker Compose configuration
├── Dockerfile.backend       # Backend Docker image
├── Dockerfile.frontend      # Frontend Docker image
└── requirements.txt         # Python dependencies
```

## 🛠️ Development

### Backend Development

The backend is a Flask application that provides RESTful APIs for:
- GO term lookup and relationships
- Protein clustering analysis
- Path finding in GO ontology graph
- CSV file processing for protein-GO annotations

**Key Dependencies:**
- Flask 3.0.0
- NetworkX 3.2.1
- Pandas 2.1.4

**API Endpoints:**
- `GET /api/go/term/<term_id>` - Get GO term details
- `POST /api/go/terms` - Get multiple GO terms
- `POST /api/go/paths` - Find paths between GO terms
- `POST /api/go/connections_csv` - Process CSV files for protein connections
- `POST /api/cluster/protein` - Cluster proteins by GO similarity

### Frontend Development

The frontend is built with Flutter for web and provides:
- Interactive GO ontology visualization
- Protein network visualization
- CSV file upload and processing
- Real-time graph rendering

**Key Dependencies:**
- Flutter 3.x
- HTTP client for API communication
- File picker for CSV uploads
- Custom graph rendering widgets

### Running in Development Mode

Use the development Docker Compose file for hot-reload:
```bash
docker-compose -f docker-compose.dev.yml up
```

### Manual Setup (without Docker)

**Backend:**
```bash
cd viz4go_backend
pip install -r ../requirements.txt
python app.py
```

**Frontend:**
```bash
cd viz4go_frontend
flutter pub get
flutter run -d chrome
```

## 📚 Documentation

- [Docker Deployment Guide](DOCKER_DEPLOYMENT.md) - Comprehensive Docker documentation
- [API Documentation](#) - Backend API reference (coming soon)
- [User Guide](#) - Application usage guide (coming soon)

## 🔧 Configuration

### Backend Configuration

The backend can be configured through environment variables:
- `FLASK_ENV` - Set to `development` or `production`
- `FLASK_DEBUG` - Enable debug mode (0 or 1)

### Frontend Configuration

The frontend API endpoint can be configured at build time:
- Default: `http://127.0.0.1:5000`
- Docker: Automatically configured to `http://localhost:5000`

## 🐛 Troubleshooting

**Port Already in Use:**
- Backend (5000): Change in `docker-compose.yml`
- Frontend (8080): Change in `docker-compose.yml`

**Backend Not Starting:**
```bash
docker-compose logs backend
```

**Frontend Can't Connect to Backend:**
- Ensure both services are running: `docker-compose ps`
- Check backend is accessible: `curl http://localhost:5000/api/go/term/GO:0008150`

**View All Logs:**
```bash
docker-compose logs -f
```

## 📊 Data

The application uses GO (Gene Ontology) data files:
- `viz4go_backend/_resources/go.obo` - Main ontology file
- Data is automatically loaded on startup
- Supports semantic similarity measures (Resnik, Lin, Wang)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

See LICENSE file for details.

## 🎯 Features

- **GO Term Visualization**: Interactive graph visualization of GO terms and relationships
- **Protein Analysis**: Upload CSV files with protein-GO annotations
- **Clustering**: Semantic and shared-GO clustering algorithms
- **Path Finding**: Find shortest paths between GO terms
- **Real-time Updates**: Dynamic graph rendering with custom layouts
- **Docker Support**: Easy deployment with zero configuration

## 💡 Use Cases

1. **Protein Function Analysis**: Upload protein annotation data and visualize functional relationships
2. **GO Term Exploration**: Navigate the GO ontology and understand term relationships
3. **Similarity Analysis**: Calculate semantic similarity between GO terms using various measures
4. **Cluster Discovery**: Find groups of functionally related proteins

## 🔬 Technical Details

**Similarity Measures:**
- Resnik (Information Content-based)
- Lin (Normalized IC-based)
- Wang (Graph structure-based)
- Pekar (Path-based)

**Clustering Algorithms:**
- Louvain community detection
- Connected components analysis
- KNN-based clustering