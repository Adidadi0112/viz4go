# Viz4GO Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User's Browser                          │
│                    http://localhost:8080                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP/HTTPS
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Host (localhost)                      │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │            viz4go_network (Docker Network)                │ │
│  │                                                           │ │
│  │  ┌─────────────────────┐    ┌─────────────────────┐     │ │
│  │  │  Frontend Container │    │  Backend Container  │     │ │
│  │  │   (viz4go_frontend) │    │  (viz4go_backend)   │     │ │
│  │  │                     │    │                     │     │ │
│  │  │  ┌───────────────┐ │    │  ┌───────────────┐ │     │ │
│  │  │  │     Nginx     │ │    │  │  Flask API    │ │     │ │
│  │  │  │   (Port 80)   │ │    │  │  (Port 5000)  │ │     │ │
│  │  │  └───────┬───────┘ │    │  └───────┬───────┘ │     │ │
│  │  │          │         │    │          │         │     │ │
│  │  │  ┌───────▼───────┐ │    │  ┌───────▼───────┐ │     │ │
│  │  │  │  Flutter Web  │ │◄──┼──┤   Routes API   │ │     │ │
│  │  │  │  Application  │ │   │  │  - go_routes   │ │     │ │
│  │  │  │  (Built)      │ │   │  │  - cluster_r.  │ │     │ │
│  │  │  └───────────────┘ │   │  └───────┬───────┘ │     │ │
│  │  │                     │   │          │         │     │ │
│  │  │  Exposed: 8080:80   │   │  ┌───────▼───────┐ │     │ │
│  │  └─────────────────────┘   │  │  Data Store   │ │     │ │
│  │                             │  │  - GO Graph   │ │     │ │
│  │                             │  │  - Similarity │ │     │ │
│  │                             │  └───────┬───────┘ │     │ │
│  │                             │          │         │     │ │
│  │                             │  ┌───────▼───────┐ │     │ │
│  │                             │  │  Volume Mounts│ │     │ │
│  │                             │  │  - _resources │ │     │ │
│  │                             │  │  - data/      │ │     │ │
│  │                             │  └───────────────┘ │     │ │
│  │                             │                     │     │ │
│  │                             │  Exposed: 5000:5000 │     │ │
│  │                             └─────────────────────┘     │ │
│  │                                                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Host File System                       │ │
│  │                                                           │ │
│  │  viz4go_backend/_resources/  ←→  Container Volume        │ │
│  │  viz4go_backend/data/        ←→  Container Volume        │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend Container (viz4go_frontend)

**Base Image**: `ghcr.io/cirruslabs/flutter:3.24.3` (build) + `nginx:alpine` (runtime)

**Components**:
- Flutter Web Application (Dart)
- Nginx Web Server
- Static Assets

**Responsibilities**:
- Serve Flutter web application
- Handle user interface
- Make API calls to backend
- Render visualizations

**Ports**:
- Internal: 80
- External: 8080
- Access: http://localhost:8080

**Build Process**:
1. Stage 1: Build Flutter web app
2. Stage 2: Copy built files to Nginx
3. Configure Nginx
4. Serve static files

### Backend Container (viz4go_backend)

**Base Image**: `python:3.11-slim`

**Components**:
- Flask Application
- GO Ontology Parser
- Similarity Measures
- API Routes

**Responsibilities**:
- Process GO ontology data
- Provide REST API endpoints
- Calculate semantic similarity
- Perform clustering analysis

**Ports**:
- Internal: 5000
- External: 5000
- Access: http://localhost:5000

**Volume Mounts**:
- `_resources/`: GO ontology files (persistent)
- `data/`: User data and cache (persistent)

## Data Flow

### 1. User Request Flow

```
User Browser
    │
    ↓ HTTP Request
Frontend (Nginx)
    │
    ↓ Serve Static Files
Flutter Web App
    │
    ↓ API Call (HTTP)
Backend (Flask)
    │
    ↓ Process Request
GO Data Store
    │
    ↓ Return Data
Backend Response
    │
    ↓ JSON
Frontend
    │
    ↓ Render
User Browser
```

### 2. CSV Upload Flow

```
User Uploads CSV
    │
    ↓
Frontend (File Picker)
    │
    ↓ HTTP POST (multipart/form-data)
Backend (/api/go/connections_csv)
    │
    ↓ Parse CSV
Extract Proteins & GO Terms
    │
    ↓ Query GO Graph
Calculate Connections
    │
    ↓ Return JSON
Frontend
    │
    ↓ Render Graph
User Sees Visualization
```

### 3. GO Term Lookup Flow

```
User Searches Term
    │
    ↓
Frontend API Call
    │
    ↓ GET /api/go/term/{id}
Backend Route
    │
    ↓ Query Data Store
GO Graph (NetworkX)
    │
    ↓ Return Term Data
Format Response
    │
    ↓ JSON
Frontend Display
```

## Network Architecture

### Docker Network: `viz4go_network`

**Type**: Bridge Network

**Connected Services**:
- `backend` (viz4go_backend)
- `frontend` (viz4go_frontend)

**Internal DNS**:
- Containers can reach each other by service name
- Backend accessible at: `http://backend:5000`
- Frontend accessible at: `http://frontend:80`

**External Access**:
- Both services exposed to host
- Backend: `localhost:5000`
- Frontend: `localhost:8080`

## Storage Architecture

### Volume Mounts

```
Host System                  Container
───────────                  ─────────
viz4go_backend/
  _resources/    ←────→    /app/viz4go_backend/_resources/
    go.obo                    go.obo
    go.obo.meta.json          go.obo.meta.json

  data/          ←────→    /app/viz4go_backend/data/
    clustering_output.md      clustering_output.md
    go.obo                    go.obo
    deepfri_test_data/        deepfri_test_data/
    mip-newfolds/             mip-newfolds/
```

**Benefits**:
- Data persists across container restarts
- Easy backup and restore
- Can be edited from host system
- Shared between container instances

## API Architecture

### Backend API Endpoints

```
/api/go/
  ├── term/<term_id>           [GET]    Get single GO term
  ├── terms                    [POST]   Get multiple GO terms
  ├── paths                    [POST]   Find paths between terms
  └── connections_csv          [POST]   Process CSV for connections

/api/cluster/
  └── protein                  [POST]   Cluster proteins by similarity
```

### Request/Response Format

**Example: Get GO Term**
```
Request:  GET /api/go/term/GO:0008150
Response: {
  "id": "GO:0008150",
  "name": "biological_process",
  "namespace": "biological_process",
  "def": "A biological process...",
  "is_obsolete": "false"
}
```

**Example: Cluster Proteins**
```
Request:  POST /api/cluster/protein
Body: {
  "protein_to_go": {
    "P1": ["GO:0001", "GO:0002"],
    "P2": ["GO:0001", "GO:0003"]
  },
  "mode": "semantic",
  "measure": "wang",
  "threshold": 0.6
}

Response: {
  "clusters": {"P1": 0, "P2": 0},
  "edges": [["P1", "P2", 0.75]]
}
```

## Security Architecture

### Container Isolation

```
┌─────────────────────────────────────┐
│         Host Operating System       │
│                                     │
│  ┌──────────────────────────────┐  │
│  │    Docker Engine             │  │
│  │                              │  │
│  │  ┌────────────────────────┐ │  │
│  │  │  Frontend Container    │ │  │
│  │  │  - Read-only FS        │ │  │
│  │  │  - Limited resources   │ │  │
│  │  └────────────────────────┘ │  │
│  │                              │  │
│  │  ┌────────────────────────┐ │  │
│  │  │  Backend Container     │ │  │
│  │  │  - Volume mounts only  │ │  │
│  │  │  - Isolated network    │ │  │
│  │  └────────────────────────┘ │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Security Features**:
- Container isolation
- Non-root users (where applicable)
- Limited resource access
- Network segregation
- Volume mount restrictions

## Scaling Architecture

### Horizontal Scaling (Future)

```
┌──────────────┐
│ Load Balancer│
└──────┬───────┘
       │
   ────┼────────────────────
   │   │              │
   ↓   ↓              ↓
┌─────────┐  ┌─────────┐  ┌─────────┐
│Frontend │  │Frontend │  │Frontend │
│Instance1│  │Instance2│  │Instance3│
└────┬────┘  └────┬────┘  └────┬────┘
     │            │            │
     └────────────┼────────────┘
                  │
                  ↓
          ┌─────────────┐
          │   Backend   │
          │  (Shared)   │
          └─────────────┘
```

## Monitoring Architecture

### Health Checks

```
Docker Compose
    │
    ├─► Backend Health Check
    │   └─► curl http://localhost:5000/api/go/term/GO:0008150
    │       ├─► Success: Container healthy
    │       └─► Failure: Restart container
    │
    └─► Frontend Health Check
        └─► wget http://localhost:80
            ├─► Success: Container healthy
            └─► Failure: Restart container
```

**Check Intervals**:
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3 attempts
- Start Period: 10-40 seconds

## Deployment Lifecycle

```
Development → Build → Test → Deploy → Monitor
    │           │       │       │         │
    │           │       │       │         └─► Logs, Stats
    │           │       │       │
    │           │       │       └─► docker-compose up
    │           │       │
    │           │       └─► Verify containers
    │           │
    │           └─► docker-compose build
    │
    └─► Code Changes
```

## Resource Requirements

### Minimum Requirements

**Backend Container**:
- CPU: 1 core
- Memory: 512MB
- Disk: 1GB

**Frontend Container**:
- CPU: 0.5 core
- Memory: 256MB
- Disk: 500MB

**Total System**:
- CPU: 2 cores
- Memory: 2GB
- Disk: 5GB (including images and data)

### Recommended Requirements

**Production**:
- CPU: 4 cores
- Memory: 4GB
- Disk: 10GB SSD
- Network: 100Mbps+

---

**Legend**:
- `│`, `─`, `┌`, `┐`, `└`, `┘` : Box drawing
- `↓`, `→`, `←` : Data flow direction
- `◄`, `►` : Bidirectional communication
- `↔` : Volume mount/sync
