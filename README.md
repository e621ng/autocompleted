# autocompleted

Tag autocomplete microservice for [e621ng](https://github.com/e621ng/e621ng). Handles `GET /tags/autocomplete.json` requests, which nginx proxies to this service internally.

## How it works

Requests arrive with a `search[name_matches]` query parameter. The service runs a two-stage PostgreSQL query:

1. **Stage A** — prefix match on tag names and alias antecedents via `LIKE`. Fast; uses an index.
2. **Stage B** — fuzzy similarity match via the PostgreSQL `pg_trgm` `%` operator. Only runs if Stage A returns no results.

Results are cached in-process with [Moka](https://github.com/moka-rs/moka) (15,000 entries, 1-hour TTL) to avoid redundant database queries.

`GET /ready` is a readiness probe for load balancers. It runs `SELECT 1;` through the connection pool and returns `200` if the database is reachable, `503` otherwise.

## Configuration

All configuration is via environment variables. Copy `.env.sample` to `.env` and fill in the values.

| Variable | Description |
|---|---|
| `SERVER_ADDR` | Bind address, e.g. `0.0.0.0:8118` |
| `PG__HOST` | PostgreSQL host |
| `PG__PORT` | PostgreSQL port |
| `PG__USER` | PostgreSQL user |
| `PG__PASSWORD` | PostgreSQL password (leave empty if using `trust` auth) |
| `PG__DBNAME` | Database name |
| `PG__POOL__MAX_SIZE` | Connection pool size |
| `RUST_LOG` | Log level, e.g. `info` or `warn,autocompleted=info` |

## Building

```bash
cargo build           # debug
cargo build --release # release
cargo clippy          # lint
cargo fmt             # format
cargo test            # tests
```

## Running standalone with Docker

```bash
docker compose up
```

This builds the image and starts the service. Make sure `.env` is populated before running.

## Development against a local e621ng instance

The e621ng stack runs its own copy of this service. You can substitute it with a local build using a Docker Compose override, without modifying the e621ng repository.

**1. Identify your database credentials.**

The e621ng postgres container is accessible on the host at port `34517` by default (see `EXPOSED_POSTGRES_PORT` in e621ng's `.env`). It uses `POSTGRES_HOST_AUTH_METHOD=trust`, so no password is needed.

The default credentials are:
- user: `e621`
- database: `e621_development`
- password: *(empty)*

**2. Create a `docker-compose.override.yml` in the e621ng directory:**

```yaml
services:
  autocompleted:
    image: autocompleted-dev
    build:
      context: ~/autocompleted
```

This overrides only the image/build source. All other settings (environment variables, network, bind address) are inherited from e621ng's `docker-compose.yml`.

**3. Build and restart the service:**

```bash
cd ~/e621ng
docker compose build autocompleted
docker compose up -d autocompleted
```

Repeat the build and restart steps whenever you make changes.

**4. Test it:**

```
http://localhost:3000/tags/autocomplete.json?search[name_matches]=fur
```

nginx proxies that path to this service at `autocompleted:8118` internally, so you never need to expose the service's port directly.
