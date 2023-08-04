{% macro generate_snapshots(schema_name, database_name=target.database, table_pattern='%', exclude='', prefix=none, suffix=none, table_names=none, source_name=none) %}

{%- set snapshots=[] -%}

{%- if source_name is not none -%}
    set source_name = schema_name
{%- endif -%}

{%- if table_names is none -%}

    {%- set tables_in_reation = dbt_utils.get_relations_by_pattern(
        schema_pattern=schema_name,
        database=database_name,
        table_pattern=table_pattern,
        exclude=exclude
    ) -%}

    {%- set tables = tables_in_reation | map(attribute='identifier') | sort -%}

{%- else -%}

    {%- set tables = table_names -%}

{%- endif -%}

{### Inherit model config ###}
{%- if config is not none -%}

    {%- set re = modules.re -%}
    {%- set model_text = model.raw_code -%}
    {%- set config_block = '(?i)(?s)^.*{{\s*config\s*\([^)]+\)\s*}}' -%}
    {%- set regex_match = re.findall(config_block, model_text) -%}
    {%- set config_block = regex_match | join("\n") | trim -%}

{%- else -%}

    {%- set config_block = """{{ config(
        target_database='" ~ database_name ~ "'
        , target_schema='" ~ schema_name ~ "'
        , strategy='check'
        , unique_key='id'
        , check_cols='all'
        , invalidate_hard_deletes=True
    ) }}""" -%}

{%- endif -%}

{### Iterate thru tables in schema ###}
{% for table in tables %}

    {### Optionally adding prefix/suffix to target table ###}
    {% if prefix is not none -%}
        {%- set target_table = prefix ~ table  -%}
    {%- elif suffix is not none -%}
        {%- set target_table = table ~ suffix -%}
    {%- else -%}
        {%- set target_table = table -%}
    {%- endif -%}

    {### Creating base model name ###}
    {%- if source_name is not none -%}
        {%- set model_name = source_name ~ "_" ~ target_table -%}
    {%- else -%}
        {%- set model_name = database_name ~ "_" ~ schema_name ~ "_" ~ target_table -%}
    {%- endif -%}

    {### Casting to lower/upper case table/model names ###}
    {%- if table is upper -%}
        {%- set target_table = target_table | upper -%}
        {%- set model_name = model_name | upper -%}
    {%- else -%}
        {%- set target_table = target_table | lower -%}
        {%- set model_name = model_name | lower -%}
    {%- endif -%}

    {### Adding alias to config block ###}
    {%- set model_config_block = re.sub("config\s*\(", "config(\n\talias='" ~ target_table ~ "',", config_block) -%}

{### Write snapshot block ###}

    {%- set base_model_sql -%}

{{ "{% snapshot " ~ model_name ~ " %}" }}

{{ model_config_block }}

select * from {% raw %}{{ source({% endraw %}'{{ source_name | lower }}', '{{ table | lower }}'{% raw %}) }}{% endraw %}

{{ "{% endsnapshot %}" }}

    {% endset %}

    {% do snapshots.append(base_model_sql) %}

{% endfor %}

{### Write snapshots to file ###}
{% if execute %}

    {% set joined = snapshots | join('\n') %}
    {{ log(joined, info=True) }}
    {% do return(joined) %}

{% endif %}

{% endmacro %}