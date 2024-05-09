# dbt-snapshot-generator

Macro that generate dbt snapshots, and log it to the command line. Read more on [snapshots](https://docs.getdbt.com/docs/build/snapshots).

This macro was totally inspired by codegen, but does not require this package. Don't know codegen? Read more about it [here](https://https://hub.getdbt.com/dbt-labs/codegen/latest/).

# Contents
- [dbt-snapshot-generator](#dbt-snapshot-generator)
- [Contents](#contents)
- [Installation instructions](#installation-instructions)
- [Macro](#macro)
  - [generate_snapshots (source)](#generate_snapshots)
    - [Arguments](#arguments)
    - [Usage:](#usage)

# Installation instructions
New to dbt packages? Read more about them [here](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/).
1. Include this package in your `packages.yml` file — check [here](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) for the latest version number:
```yml
packages:
  - package: dbt-labs/dbt_utils
    version: X.X.X ## update to latest version here
```
2. Run `dbt deps` to install the package.
3. Copy generate_snapshots.sql macro to your dbt project macros folder.
# Macro
## generate_snapshots ([source](macros/generate_snapshots.sql))
This macro generates multiple snapshots into a single SQL file for a database schema, which you can then copy into your snapshot folder.

### Arguments
* `schema_name` (required): The schema name that contains your source data.
* `database_name` (optional, default=target.database): The database that your
source data is in.
* `table_pattern` (optional, default='%'): A table prefix / postfix that you
want to subselect from all available tables within a given schema.
* `exclude` (optional, default=''): A string you want to exclude from the selection criteria.
* `prefix` (optional, default=none): Target table prefix that you want to generate the tables for. Ex.: scd_\<snapshotted-table\>.
* `suffix` (optional, default=none): Target table suffix that you want to generate the tables for. Ex.: \<snapshotted-table\>_scd.
* `table_names` (optional, default=none): A list of tables that you want to generate the source definitions for.
* `source_name` (optional, default=none): Source name for the generated snapshot query. Schema name is the default \<source_name\>. Ex.:
```
select * from {{ source('<source_name>', '<table_name'>') }}
```

### Usage:
1. Copy the macro into a statement tab in the dbt Cloud IDE, or into an analysis file, and compile your code. Ex.:

analyses/example.sql
```
{{ generate_snapshots('jaffle_shop') }}
```

2. Another cool feature is to call generate_snapshots macro from analyses folder with a config block. All snapshot models generated will inherit the same config block for your convenience. By default the generated snapshot will create a standard configuration block. Read more about it on [snapshot-configs](https://docs.getdbt.com/reference/snapshot-configs) Ex.:

analyses/example.sql
```
{{
    config(
      target_database='analytics'
      , target_schema='snapshots'
      , unique_key='id'
      , strategy='timestamp'
      , updated_at='updated_at'
    )
}}

{{ generate_snapshots('jaffle_shop') }}
```

Then run
```
$ dbt compile --select analyses/example.sql
```

3. Alternatively, call the macro as an [operation](https://docs.getdbt.com/docs/using-operations):

```
$ dbt run-operation generate_snapshots --args 'schema_name: jaffle_shop'
```

or

```
# for multiple arguments, use the dict syntax
$ dbt run-operation generate_snapshots --args '{"schema_name": "jaffle_shop", "database_name": "raw", "table_names":["table_1", "table_2"]}'
```



4. Copy and paste the generated snapshot file from dbt target folder or the logged code into your dbt snapshots folder or file.
