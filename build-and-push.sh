#!/bin/bash

# Build and Push Script for PostgreSQL DataLake Image
# Usage: ./build-and-push.sh [tag]

set -e

# Configuration
DOCKER_USERNAME="rozaydin"
IMAGE_NAME="postgres-datalake"
DEFAULT_TAG="latest"
TAG=${1:-$DEFAULT_TAG}
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

echo "🚀 Building PostgreSQL DataLake Image..."
echo "Image: ${FULL_IMAGE_NAME}"
echo "=========================================="

# Build the image
echo "📦 Building Docker image..."
docker build -t "${FULL_IMAGE_NAME}" .

# Tag as latest if building a version tag
if [ "$TAG" != "latest" ]; then
    echo "🏷️  Tagging as latest..."
    docker tag "${FULL_IMAGE_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
fi

# Test the image
echo "🧪 Testing the image..."
docker run --rm -d --name test-postgres-datalake \
    -e POSTGRES_PASSWORD=test123 \
    -p 15432:5432 \
    "${FULL_IMAGE_NAME}"

# Wait for PostgreSQL to start
echo "⏳ Waiting for PostgreSQL to start..."
sleep 10

# Test connection and extensions
echo "🔍 Testing database connection and extensions..."
docker exec test-postgres-datalake psql -U postgres -c "SELECT version();"
docker exec test-postgres-datalake psql -U postgres -c "SELECT name FROM pg_available_extensions WHERE name IN ('vector', 'postgis', 'pg_cron', 'duckdb_fdw', 'clickhouse_fdw', 'pg_partman') ORDER BY name;"

# Clean up test container
echo "🧹 Cleaning up test container..."
docker stop test-postgres-datalake

echo "✅ Image built and tested successfully!"

# Ask for confirmation before pushing
read -p "🚀 Push to Docker Hub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to Docker Hub..."
    
    # Push the tagged version
    docker push "${FULL_IMAGE_NAME}"
    
    # Push latest if this is a version tag
    if [ "$TAG" != "latest" ]; then
        docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    fi
    
    echo "✅ Successfully pushed to Docker Hub!"
    echo "🔗 Image available at: https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
else
    echo "⏭️  Skipping push to Docker Hub"
fi

echo "🎉 Done!"