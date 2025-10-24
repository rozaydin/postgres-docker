-- ===========================================================
-- PostgreSQL 18 Datalake Init Script
-- Enables core, contrib, FDW, and analytical extensions
-- ===========================================================

-- --- Core / Contrib ---
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS tablefunc;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE EXTENSION IF NOT EXISTS file_fdw;

-- --- External FDWs ---
CREATE EXTENSION IF NOT EXISTS clickhouse_fdw;
CREATE EXTENSION IF NOT EXISTS duckdb_fdw;

-- --- Partitioning / Scheduling ---
CREATE EXTENSION IF NOT EXISTS pg_partman;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- --- ML / Vector ---
CREATE EXTENSION IF NOT EXISTS vector;

-- --- Spatial / GIS ---
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- --- Notes ---
-- pg_cron jobs live in the database defined by cron.database_name
-- pg_partman requires maintenance jobs or pg_cron triggers for partition roll-over
-- postgis_topology requires postgis installed first