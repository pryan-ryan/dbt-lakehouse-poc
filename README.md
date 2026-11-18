# dbt Lakehouse POC

A small dbt project for Trino on the Cloudera Lakehouse Engine. It reads CSV-backed tables from the Trino Hive
catalog `raw` and builds Iceberg tables in the Harmony (Polaris) catalog `iceberg-awc`.

| Layer | Where | Models |
| --- | --- | --- |
| Raw | `raw.landing.*` (CSV on S3, all columns varchar) | `customers`, `orders`, `products` (sample files in `data/`) |
| Staging | ephemeral (no objects) | `stg_customers`, `stg_orders`, `stg_products` (typed) |
| Marts | Iceberg tables in `"iceberg-awc".<your schema>` | `dim_customers`, `fct_orders`, with tests |

## Run it in a Coder workspace

The `dbt-trino` workspace template clones this repository to `~/project` and pulls it at every start.

```bash
trino-login          # once a day: Keycloak password -> Trino token in ~/.trino-jwt
cd ~/project
dbt debug
dbt build
```

dbt writes to the schema named after your username (`DBT_LAKE_SCHEMA`). You can also use `<username>_<anything>`
(set `DBT_LAKE_SCHEMA=<username>_dev`). Other users' schemas are not visible to you.

## Settings

`profiles.yml` holds no credentials; every value comes from the environment (set by the workspace):

| Variable | Meaning |
| --- | --- |
| `TRINO_HOST`, `TRINO_PORT` | Trino coordinator (HTTPS) |
| `TRINO_USER`, `TRINO_JWT` | your username and token (`trino-login`) |
| `DBT_RAW_CATALOG`, `DBT_RAW_SCHEMA` | source tables (default `raw`, `landing`) |
| `DBT_LAKE_CATALOG`, `DBT_LAKE_SCHEMA` | target catalog and schema |

## Working with git

Commit and push your changes as usual. The workspace pulls only when your working tree is clean, so local
changes are never overwritten. Pushing needs your own GitHub credentials (for example a personal access token).
