{# Run one SQL statement (DDL, insert, select) as you, and print any rows it returns:
   dbt run-operation run_sql --args '{sql: "create schema if not exists raw.user001_files"}'
   `dbt show --inline` cannot run DDL, because it appends a `limit`. #}
{% macro run_sql(sql) %}
    {% set result = run_query(sql) %}
    {% if result is not none and result.rows | length > 0 %}
        {% do result.print_table(max_rows=100, max_columns=20, max_column_width=40) %}
    {% endif %}
{% endmacro %}
