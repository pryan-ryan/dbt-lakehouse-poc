{#
  Drop everything you built: the tables and views in YOUR schemas, then the schemas themselves.
  Your schemas are <lake schema> and <lake schema>_* (for example user001, user001_dev, user001_raw, user001_files)
  in the lake catalog (iceberg-awc) and in the raw catalog (raw). Shared schemas (landing, marts) are never touched,
  and Ranger would refuse them anyway.

  Dry run (default, lists what would be dropped):
    dbt run-operation cleanup
  Drop for real:
    dbt run-operation cleanup --args '{dry_run: false}'
  Options:
    schemas: [user001_dev]   only these schemas (default: all of yours)
    keep_schemas: true       drop the tables and views, keep the empty schemas
    include_raw: false       leave the raw catalog alone (your seeds and own raw tables)
  `dbt build` creates everything again.
#}
{% macro cleanup(dry_run=true, schemas=none, keep_schemas=false, include_raw=true) %}
  {% set me = target.schema | lower %}
  {% if me in ['', 'marts', 'landing', 'default', 'information_schema'] %}
    {{ exceptions.raise_compiler_error("cleanup: lake schema '" ~ me ~ "' is shared; set DBT_LAKE_SCHEMA to your own schema") }}
  {% endif %}
  {% set catalogs = [target.database] %}
  {% if include_raw %}
    {% do catalogs.append(env_var('DBT_RAW_CATALOG', 'raw')) %}
  {% endif %}
  {% set mine = "(schema_name = '" ~ me ~ "' or schema_name like '" ~ me ~ "\\_%' escape '\\')" %}
  {% set statements = [] %}
  {% for cat in catalogs %}
    {% set found = run_query('select schema_name from "' ~ cat ~ '".information_schema.schemata where ' ~ mine ~ ' order by 1') %}
    {% for row in found.rows %}
      {% set s = row[0] %}
      {% if schemas is none or s in schemas %}
        {% set objects = run_query('select table_name, table_type from "' ~ cat ~ '".information_schema.tables where table_schema = \'' ~ s ~ '\' order by 1') %}
        {% for obj in objects.rows %}
          {% set kind = 'view' if obj[1] == 'VIEW' else 'table' %}
          {% do statements.append('drop ' ~ kind ~ ' if exists "' ~ cat ~ '"."' ~ s ~ '"."' ~ obj[0] ~ '"') %}
        {% endfor %}
        {% if not keep_schemas %}
          {% do statements.append('drop schema if exists "' ~ cat ~ '"."' ~ s ~ '"') %}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endfor %}
  {% if statements | length == 0 %}
    {{ log("cleanup: nothing to drop for '" ~ me ~ "'", info=true) }}
  {% endif %}
  {% for sql in statements %}
    {% if dry_run %}
      {{ log("would run: " ~ sql, info=true) }}
    {% else %}
      {{ log("running: " ~ sql, info=true) }}
      {% do run_query(sql) %}
    {% endif %}
  {% endfor %}
  {% if dry_run and statements %}
    {{ log("Dry run: nothing dropped. Run again with --args '{dry_run: false}' to drop these " ~ statements | length ~ " objects.", info=true) }}
  {% endif %}
{% endmacro %}
