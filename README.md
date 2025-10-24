# PostgreSQL 18 DataLake Image

[![Docker Hub](https://img.shields.io/docker/v/rozaydin/postgres-datalake?label=Docker%20Hub)](https://hub.docker.com/r/rozaydin/postgres-datalake)
[![Docker Image Size](https://img.shields.io/docker/image-size/rozaydin/postgres-datalake)](https://hub.docker.com/r/rozaydin/postgres-datalake)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-blue)](https://www.postgresql.org/)

A production-ready PostgreSQL 18 image optimized for data lake and analytical workloads. Built on Debian Bookworm with pre-configured extensions for modern data processing, foreign data wrappers, vector operations, and geospatial analysis.

## 🚀 Features

### Core Extensions

- **PostgreSQL Contrib**: `uuid-ossp`, `pgcrypto`, `hstore`, `ltree`, `tablefunc`, `postgres_fdw`, `file_fdw`
- **Statistics & Monitoring**: `pg_stat_statements` with enhanced tracking
- **Job Scheduling**: `pg_cron` for automated database tasks

### File Format Support

- **file_fdw**: Built-in support for CSV, TSV, and other delimited files
- **pg_parquet**: *Coming soon* - Native Parquet support (requires Rust toolchain)

### Foreign Data Wrappers (FDW)

- **postgres_fdw**: Connect to other PostgreSQL databases
- **ClickHouse FDW**: *Temporarily unavailable* - Waiting for PostgreSQL 18 compatibility

### Data Management

- **pg_partman**: Automated table partitioning and maintenance
- **pgvector**: Vector similarity search and embeddings (AI/ML workloads)

### Geospatial Analysis

- **PostGIS**: Full spatial database capabilities
- **PostGIS Raster**: Raster data support
- **PostGIS Topology**: Topological analysis

## 📦 Quick Start

### Basic Usage

```bash
# Pull and run the image
docker run -d \
  --name postgres-datalake \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=your_secure_password \
  -e POSTGRES_DB=datalake \
  rozaydin/postgres-datalake:latest
```

### With Persistent Storage

```bash
# Create a volume for data persistence
docker volume create postgres-datalake-data

# Run with persistent storage
docker run -d \
  --name postgres-datalake \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=your_secure_password \
  -e POSTGRES_DB=datalake \
  -v postgres-datalake-data:/var/lib/postgresql/data \
  rozaydin/postgres-datalake:latest
```

### Docker Compose

```yaml
version: "3.8"
services:
  postgres-datalake:
    image: rozaydin/postgres-datalake:latest
    container_name: postgres-datalake
    environment:
      POSTGRES_PASSWORD: your_secure_password
      POSTGRES_DB: datalake
      POSTGRES_USER: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-datalake-data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 5s
      retries: 5

volumes:
  postgres-datalake-data:
```

## ⚙️ Configuration

### Pre-configured Settings

The image comes with optimized settings for **2-core/8GB RAM** systems:

- **Memory**: 2GB shared_buffers, 6GB effective_cache_size
- **Connections**: Up to 80 concurrent connections
- **Parallelism**: Configured for 2-4 worker processes
- **WAL**: Optimized for performance with compression
- **Logging**: Comprehensive query and performance logging

### Environment Variables

All standard PostgreSQL environment variables are supported:

- `POSTGRES_PASSWORD` - Required: Database superuser password
- `POSTGRES_USER` - Optional: Superuser name (default: postgres)
- `POSTGRES_DB` - Optional: Default database name
- `POSTGRES_INITDB_ARGS` - Optional: Additional initdb arguments

### Custom Configuration

To override the default configuration:

```bash
# Mount your own postgresql.conf
docker run -d \
  --name postgres-datalake \
  -v /path/to/your/postgresql.conf:/etc/postgresql/postgresql.conf \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=your_password \
  rozaydin/postgres-datalake:latest
```

## 🔌 Extension Usage Examples

### Vector Similarity Search

```sql
-- Create a table with vector embeddings
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(384)
);

-- Find similar documents
SELECT content
FROM documents
ORDER BY embedding <-> '[0.1,0.2,0.3,...]'::vector
LIMIT 5;
```

### File Format Support with file_fdw

```sql
-- Create a foreign table for CSV files
CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER file_server FOREIGN DATA WRAPPER file_fdw;

-- Map a CSV file as a foreign table
CREATE FOREIGN TABLE sales_data (
    id INTEGER,
    product_name TEXT,
    sale_date DATE,
    amount NUMERIC
) SERVER file_server
OPTIONS (filename '/data/sales.csv', format 'csv', header 'true');

-- Query CSV data directly
SELECT product_name, SUM(amount) as total_sales
FROM sales_data 
WHERE sale_date >= '2024-01-01'
GROUP BY product_name;

-- Create table from CSV data
CREATE TABLE imported_sales AS 
SELECT * FROM sales_data WHERE amount > 100;
```### Automated Partitioning

```sql
-- Set up automatic monthly partitioning
SELECT partman.create_parent(
    p_parent_table => 'public.sales',
    p_control => 'sale_date',
    p_type => 'range',
    p_interval => 'monthly'
);
```

### Scheduled Jobs with pg_cron

```sql
-- Schedule a daily cleanup job
SELECT cron.schedule('daily-cleanup', '0 2 * * *', 'VACUUM ANALYZE;');

-- List scheduled jobs
SELECT * FROM cron.job;
```

## 🏗️ System Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **RAM**: 4GB (8GB recommended)
- **Storage**: 10GB+ for database files
- **OS**: Any Docker-compatible system

### Optimized For

- **CPU**: 2-4 cores
- **RAM**: 8GB+
- **Storage**: SSD recommended for best performance

## 📊 Performance Tuning

### Memory Scaling

For different memory configurations, adjust these parameters:

| System RAM | shared_buffers | effective_cache_size | work_mem |
| ---------- | -------------- | -------------------- | -------- |
| 4GB        | 1GB            | 3GB                  | 16MB     |
| 8GB        | 2GB            | 6GB                  | 32MB     |
| 16GB       | 4GB            | 12GB                 | 64MB     |
| 32GB       | 8GB            | 24GB                 | 128MB    |

### Connection Pooling

For high-concurrency workloads, consider using pgBouncer:

```yaml
# Add to docker-compose.yml
pgbouncer:
  image: pgbouncer/pgbouncer:latest
  environment:
    DATABASES_HOST: postgres-datalake
    DATABASES_PORT: 5432
    DATABASES_USER: postgres
    DATABASES_PASSWORD: your_password
    DATABASES_DBNAME: datalake
  ports:
    - "6432:5432"
```

## 🔍 Monitoring & Maintenance

### Health Checks

```bash
# Check container health
docker ps

# View logs
docker logs postgres-datalake

# Connect to database
docker exec -it postgres-datalake psql -U postgres -d datalake
```

### Performance Monitoring

```sql
-- Check slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Monitor table sizes
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## 🛠️ Building from Source

```bash
# Clone the repository
git clone https://github.com/rozaydin/postgres-docker.git
cd postgres-docker

# Build the image
docker build -t postgres-datalake:latest .

# Run locally
docker run -d \
  --name postgres-datalake \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=test123 \
  postgres-datalake:latest
```

## 📋 Extension Versions

| Extension      | Source                                                          | Purpose                 | Status                    |
| -------------- | --------------------------------------------------------------- | ----------------------- | ------------------------- |
| file_fdw       | PostgreSQL Contrib                                              | CSV/TSV file support    | ✅ Available              |
| pg_parquet     | [adriangb/pg_parquet](https://github.com/adriangb/pg_parquet)   | Native Parquet support  | ⏳ Requires Rust toolchain |
| clickhouse_fdw | [ildus/clickhouse_fdw](https://github.com/ildus/clickhouse_fdw) | ClickHouse connectivity | ⏳ Awaiting PG18 support  |
| pg_partman     | [pgpartman/pg_partman](https://github.com/pgpartman/pg_partman) | Automated partitioning  | ✅ Available              |
| pgvector       | [pgvector/pgvector](https://github.com/pgvector/pgvector)       | Vector operations       | ✅ Available              |
| pg_cron        | PostgreSQL APT                                                  | Job scheduling          | ✅ Available              |
| PostGIS        | PostgreSQL APT                                                  | Geospatial analysis     | ✅ Available              |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/rozaydin/postgres-docker/issues)
- **Documentation**: [PostgreSQL Documentation](https://www.postgresql.org/docs/18/)
- **Extensions**: Check individual extension documentation for specific usage

---

**Built with ❤️ for modern data workloads**
