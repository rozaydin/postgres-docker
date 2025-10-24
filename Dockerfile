# ===========================================================
# PostgreSQL 18 DataLake Image (Debian Bookworm)
# Includes:
#   - clickhouse_fdw
#   - duckdb_fdw (Parquet/CSV/JSON)
#   - pg_partman
#   - pgvector
#   - pg_cron
#   - PostGIS (postgis, raster, topology)
#   - contrib (uuid-ossp, pgcrypto, hstore, ltree, tablefunc, postgres_fdw, file_fdw)
# ===========================================================

# ---------- BUILD STAGE ----------
FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /src

# PGDG repo for server-dev-18
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg lsb-release apt-transport-https && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update

# Toolchain + PGXS headers + deps (DuckDB dev comes from Debian)
RUN apt-get install -y --no-install-recommends \
    build-essential cmake git pkg-config \
    libcurl4-openssl-dev libssl-dev uuid-dev \
    libpq-dev postgresql-server-dev-18 libduckdb-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- clickhouse_fdw ----
RUN git clone --depth=1 https://github.com/ildus/clickhouse_fdw.git
WORKDIR /src/clickhouse_fdw
RUN mkdir build && cd build && cmake .. && make -j"$(nproc)" && make install

# ---- duckdb_fdw ----
WORKDIR /src
RUN git clone --depth=1 https://github.com/alitrack/duckdb_fdw.git
WORKDIR /src/duckdb_fdw
RUN make -j"$(nproc)" && make install

# ---- pg_partman ----
WORKDIR /src
RUN git clone --depth=1 https://github.com/pgpartman/pg_partman.git
WORKDIR /src/pg_partman
RUN make -j"$(nproc)" && make install

# ---- pgvector ----
WORKDIR /src
RUN git clone --depth=1 https://github.com/pgvector/pgvector.git
WORKDIR /src/pgvector
RUN make -j"$(nproc)" && make install


# ---------- RUNTIME STAGE ----------
FROM postgres:18-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Contribs + pg_cron + PostGIS + CA certs
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib-18 \
    postgresql-18-cron \
    postgresql-18-postgis-3 \
    postgresql-18-postgis-3-scripts \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy built artifacts from build stage (libs + extension control/sql)
COPY --from=build /usr/lib/postgresql/18/lib/ /usr/lib/postgresql/18/lib/
COPY --from=build /usr/share/postgresql/18/extension/ /usr/share/postgresql/18/extension/

# Copy configuration and initialization files
COPY ./postgresql.conf /etc/postgresql/postgresql.conf
COPY ./init.sql /docker-entrypoint-initdb.d/00-extensions.sql

# Use custom configuration
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
    CMD pg_isready -U postgres || exit 1