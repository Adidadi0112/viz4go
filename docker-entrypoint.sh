#!/bin/sh
# Script to inject backend URL into Flutter web app at runtime

# Default backend URL (can be overridden by environment variable)
BACKEND_URL=${BACKEND_URL:-"http://localhost:5000"}

# Find and replace the API endpoint in the built JavaScript files
echo "Configuring backend URL to: $BACKEND_URL"

# This will update any hardcoded localhost references to the backend
# Note: This is a simple approach. For production, consider using environment-specific builds
find /usr/share/nginx/html -type f -name "*.js" -exec sed -i "s|http://127.0.0.1:5000|$BACKEND_URL|g" {} +
find /usr/share/nginx/html -type f -name "*.js" -exec sed -i "s|http://localhost:5000|$BACKEND_URL|g" {} +

echo "Starting Nginx..."
exec nginx -g 'daemon off;'
