# dbt Lakehouse POC

A small dbt project for Trino on the Cloudera Lakehouse Engine. It reads CSV-backed tables from the Trino Hive
catalog `raw` and builds Iceberg tables in the Harmony (Polaris) catalog `iceberg-awc`.

```
raw.landing.customers ─┐          stg_customers ─┐
raw.landing.orders    ─┼─ staging ─ stg_orders  ─┼─ marts ─ fct_orders, dim_customers
raw.landing.products  ─┘          stg_products  ─┘          ("iceberg-awc".<your schema>)
```

| Layer | Where | Models |
| --- | --- | --- |
| Raw | `raw.landing.*` (CSV files on S3, all columns varchar; loaded by the platform team) | `customers`, `orders`, `products` (sample files in `data/`) |
| Staging | ephemeral (compiled into the marts, no tables) | `stg_customers`, `stg_orders`, `stg_products`: cast to proper types |
| Marts | Iceberg tables in `"iceberg-awc".<your schema>` | `fct_orders` (one row per order, with revenue), `dim_customers` (shipped orders and revenue per customer), with 7 tests |

## What you can do

- Read every table in `raw`.
- Create, change and drop tables in your own schemas of `iceberg-awc`: `<username>` and `<username>_<anything>`
  (for example `user001`, `user001_dev`). dbt creates the schema on the first run.
- Other users' schemas are not visible to you, and yours are not visible to them.

## Step by step in a Coder workspace

### 1. Open your workspace

Sign in to Coder with your Keycloak login, create a workspace from the template **dbt-trino** (or start your
existing one) and open **VS Code** or the **Terminal**. The first start installs dbt (about 1 minute) and clones
this repository to `~/project`. Every later start pulls the latest commits, unless you have uncommitted changes.

### 2. Sign in to Trino (once a day)

```bash
trino-login
```

Enter your Keycloak password. Your token is saved in `~/.trino-jwt` and is valid for about 24 hours. Run
`trino-login` again when dbt reports `401` or `Unauthorized`. Open a new terminal afterwards, or keep using the
same one: `trino-login` also sets `TRINO_JWT` in the current shell.

### 3. Check the connection

```bash
cd ~/project
dbt debug
```

The output ends with `All checks passed!`.

### 4. Run the whole pipeline

```bash
dbt build
```

This creates (or replaces) the marts and runs the tests: `PASS=9 ... ERROR=0`. The tables are now in
`"iceberg-awc".<username>`.

### 5. Look at the results

```bash
dbt show --select fct_orders --limit 5
dbt show --inline "select country, count(*) as customers, sum(shipped_revenue) as revenue from {{ ref('dim_customers') }} group by 1 order by 3 desc"
```

You can also query the tables from any Trino client (the Lakehouse UI's SQL editor, for example) as
`select * from "iceberg-awc".<username>.fct_orders`. The catalog name contains a hyphen, so it needs the quotes.

### 6. Run parts of the pipeline

```bash
dbt ls                               # list models, sources and tests
dbt run --select fct_orders          # build one model
dbt run --select +dim_customers      # a model and everything upstream of it
dbt test --select dim_customers      # only the tests of one model
```

### 7. Work in a separate schema

```bash
DBT_LAKE_SCHEMA="${TRINO_USER}_dev" dbt build    # for example into user001_dev
```

Without the prefix, dbt uses your main schema again.

### 8. Add your own model

Create `models/marts/revenue_by_category.sql`:

```sql
select
    category,
    count(*) as orders,
    sum(revenue) as revenue
from {{ ref('fct_orders') }}
where status = 'shipped'
group by 1
```

Then `dbt run --select revenue_by_category` and `dbt show --select revenue_by_category`.

### 9. Documentation

```bash
dbt docs generate
dbt docs serve --port 8081
```

Open port 8081 through Coder's port forwarding (the workspace page lists the open ports).

### 10. Save your work in git

```bash
git checkout -b my-change
git add models/
git commit -m "Add revenue by category"
git push -u origin my-change     # needs your own GitHub credentials (a personal access token)
```

dbt's output folders (`target/`, `logs/`) are ignored by git, so running dbt keeps the working tree clean and the
workspace can still pull updates at the next start.

## Settings

`profiles.yml` holds no credentials; every value comes from the environment, set by the workspace:

| Variable | Meaning |
| --- | --- |
| `TRINO_HOST`, `TRINO_PORT` | Trino coordinator (HTTPS) |
| `TRINO_USER`, `TRINO_JWT` | your username and token (`trino-login`) |
| `DBT_RAW_CATALOG`, `DBT_RAW_SCHEMA` | source tables (default `raw`, `landing`) |
| `DBT_LAKE_CATALOG`, `DBT_LAKE_SCHEMA` | target catalog and schema (default: `iceberg-awc`, your username) |

## Troubleshooting

| Message | Cause and fix |
| --- | --- |
| `401` / `Unauthorized` | The token expired: run `trino-login`. |
| `Access Denied: Cannot create schema ...` | The schema is not `<username>` or `<username>_*`: check `DBT_LAKE_SCHEMA`. |
| `Access Denied: Cannot select from table ...` | The table is in another user's schema; ask the platform team for access. |
| `dbt: command not found` | The first start is still installing dbt; wait a minute and open a new terminal. |
| The workspace did not pull new commits | You have uncommitted changes in `~/project`: commit or stash them, then `git pull`. |
