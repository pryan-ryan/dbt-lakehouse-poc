{# Use a model's custom schema as is (not <target schema>_<custom schema>), so marts land exactly where configured. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ (custom_schema_name or target.schema) | trim }}
{%- endmacro %}
