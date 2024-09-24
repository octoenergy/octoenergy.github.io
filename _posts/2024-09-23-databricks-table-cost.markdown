---
title: Estimating cost per dbt model in Databricks
layout: post
category: news
author: Evelyn Byer
hex: 0e1720
---

Many data teams across Kraken are using Databricks and dbt to build their analytics lakehouses. Databricks is a powerful tool that allows you to build and analyze dbt models quickly with Spark. However with an increasing number of analysts, complexity of queries and growing dbt projects, costs of building these models can quickly rise. To help optimize costs we first need to understand them. So, in this post we'll walk through one method to estimate the cost of running any dbt model in Databricks which can then be used for budgeting or prioritizing technical debt clean-up.

In this post, we'll be using the following tools:
- Databricks Unity Catalog - [system tables](https://docs.databricks.com/en/admin/system-tables/index.html)
- [dbt Core](https://docs.getdbt.com/docs/core/installation-overview) - a dbt project running on Databricks
- [elementary-data](https://docs.elementary-data.com/introduction) - elementary dbt metadata tables

## Overview

To estimate the cost of running each dbt model over a week in Databricks we will:
1. Calculate the total cost accrued by your Databricks SQL warehouse (`cost_per_warehouse`)
2. Cacluate the total execution time of all queries run against the warehouse (`total_warehouse_execution_time`)
3. Calculate the execution time of each dbt model and its associated tests (`model_execution_time`)
4. Calculate every dbt model's estimated cost using our algorithm: `cost_per_model = cost_per_warehouse * (model_execution_time / total_warehouse_execution_time)`

**Assumptions:**
- dbt project is running against only one Databricks SQL warehouse
- These costs ignore additional cloud compute and storage costs behind Databricks - the estimates explained here are therefore conservative

***
## Step 1: Calculate the total cost accrued by your Databricks SQL warehouse

Databricks costs are based on processing units called [Databricks units (DBUs)](https://www.databricks.com/product/pricing). To get total costs of a warehouse, we need to multiply the number of DBUs used, by the dollar rate per DBU at the time of use. Luckily, we can easily find this using Databricks system tables: `system.billing.usage` and `system.billing.list_prices`. Summing the price column gives the total cost of running the warehouse for the week (note that all costs are in USD).

```sql
SELECT
    SUM(price.default * databricks_usage.usage_quantity) AS price
FROM 
    system.billing.usage AS databricks_usage
INNER JOIN 
    system.billing.list_prices AS price
    ON databricks_usage.sku_name = price.sku_name
    AND databricks_usage.usage_start_time >= price.price_start_time
    AND databricks_usage.usage_start_time <= COALESCE(price.price_end_time, TIMESTAMP('2099-09-09'))
WHERE 
    databricks_usage.usage_metadata.warehouse_id = {WAREHOUSE_ID}
    AND databricks_usage.usage_start_time >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY;
  ```
Now we have the value for the first part of our algorithm: `cost_per_warehouse` = `price`.

***
## Step 2: Cacluate the total execution time of all queries run against the warehouse
We can use the `system.query.history` table to get the total execution time of all queries run against the warehouse over the las week.

```sql
SELECT 
    -- Extracting dbt object name
    REGEXP_EXTRACT(statement_text, '(?:"node_id": ")(.*?)(?="}|$)') AS object_name,
    statement_text,
    start_time,
    end_time,
    total_duration_ms,
    CASE 
        -- Categorizing dbt statements - if warehouse is running multiple dbt projects
        WHEN statement_text LIKE '%", "target_name": "prod"%' THEN 'PRODUCTION'
        ELSE 'OTHER'
    END AS dbt_project_category
FROM 
    system.query.history
WHERE 
    start_time >= DATE_SUB(CURRENT_DATE(), 7) -- last seven days
    AND client_application = 'Databricks Dbt'
    AND compute.warehouse_id = {WAREHOUSE_ID};
```
The above query returns the total queries against the warehouse for the last seven days, along with additional information like their total duration, dbt object name, and dbt production category (if running different dbt processes against the same endpoint). We will be using the above results in the following steps, but to determine the total runtime against our warehouse, the code above can be extended:

```sql
WITH all_queries AS (
    SELECT 
        -- Extracting dbt object name
        REGEXP_EXTRACT(statement_text, '(?:"node_id": ")(.*?)(?="}|$)') AS object_name,
        statement_text,
        start_time,
        end_time,
        total_duration_ms,
        CASE 
            -- Categorizing based on target_name in the statement
            WHEN statement_text LIKE '%", "target_name": "prod"%' THEN 'PRODUCTION'
            ELSE 'OTHER'
        END AS dbt_project_category
    FROM 
        system.query.history
    WHERE 
        start_time >= DATE_SUB(CURRENT_DATE(), 7) -- last seven days
        AND client_application = 'Databricks Dbt'
        AND compute.warehouse_id = {WAREHOUSE_ID}
),

SELECT 
    CAST(SUM(total_duration_ms) AS DECIMAL) / 3600000 AS total_execution_time_hours
FROM 
    all_queries;

```
Now we have the value for the denominator of our algorithm: `total_warehouse_execution_time` = `total_execution_time_hours`. 

***
## Step 3: Calculate the execution time of each dbt model and its associated tests
In this step, we bring in elementary tables to map tests to their associated models using the column `parent_model_unique_id` in the elementary table `dbt_tests`. This allows us to group warehouse queries around specific models, rather than treating tests and models as separate. 

```sql
WITH all_queries AS (
    SELECT 
        -- Extracting dbt object name
        REGEXP_EXTRACT(statement_text, '(?:"node_id": ")(.*?)(?="}|$)') AS object_name,
        total_duration_ms,
        CASE 
            -- Categorizing based on target_name in the statement
            WHEN statement_text LIKE '%", "target_name": "prod"%' THEN 'PRODUCTION'
            ELSE 'OTHER'
        END AS dbt_project_category
    FROM 
        system.query.history
    WHERE 
        start_time >= DATE_SUB(CURRENT_DATE(), 7) -- last seven days
        AND client_application = 'Databricks Dbt'
        AND compute.warehouse_id = {WAREHOUSE_ID}
)

-- Link tests to their parent model
SELECT 
    COALESCE(tests.parent_model_unique_id, aq.object_name) AS dbt_model_id,
    CAST(SUM(total_duration_ms) AS DECIMAL) / 3600000 AS model_execution_time_hours
FROM 
    all_queries aq
LEFT JOIN 
    {ELEMENTARY_CATALOG}.elementary.dbt_tests tests
    ON aq.object_name = tests.unique_id
WHERE 
    aq.dbt_project_category = 'PRODUCTION'
GROUP BY 
    dbt_model_id;
```
The above query returns the total execution time of each dbt model and its associated tests over the last seven days. This gives us the final element of our algorithm: `model_execution_time` = `model_execution_time_hours`.

***
## Step 4: Putting it all together
To get the weekly cost of all models in USD, the following code combining all the above SQL can be used:

```sql
-- select * from system.billing.list_prices limit 10

WITH price AS (
    SELECT
        SUM(prices.pricing.default * databricks_usage.usage_quantity) AS price
    FROM 
        system.billing.usage AS databricks_usage
    INNER JOIN 
        system.billing.list_prices AS prices
        ON databricks_usage.sku_name = prices.sku_name
        AND databricks_usage.usage_start_time >= prices.price_start_time
        AND databricks_usage.usage_start_time <= COALESCE(prices.price_end_time, TIMESTAMP('2099-09-09'))
    WHERE 
        databricks_usage.usage_metadata.warehouse_id = {WAREHOUSE_ID}
        AND databricks_usage.usage_start_time >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY
),
all_queries AS (
    SELECT 
        -- Extracting dbt object name
        REGEXP_EXTRACT(statement_text, '(?:"node_id": ")(.*?)(?="}|$)') AS object_name,
        total_duration_ms,
        CASE 
            -- Categorizing based on target_name in the statement
            WHEN statement_text LIKE '%", "target_name": "prod"%' THEN 'PRODUCTION'
            ELSE 'OTHER'
        END AS dbt_project_category
    FROM 
        system.query.history
    WHERE 
        start_time >= DATE_SUB(CURRENT_DATE(), 7) -- last seven days
        AND client_application = 'Databricks Dbt'
        AND compute.warehouse_id = {WAREHOUSE_ID}
),
total_execution_time AS (
    SELECT 
        CAST(SUM(total_duration_ms) AS DECIMAL) / 3600000 AS total_execution_time_hours
    FROM 
        all_queries
),
test_model_map AS (
    -- Link tests to their parent model
    SELECT 
        COALESCE(tests.parent_model_unique_id, aq.object_name) AS dbt_model_id,
        CAST(SUM(total_duration_ms) AS DECIMAL) / 3600000 AS model_execution_time_hours
    FROM 
        all_queries aq
    LEFT JOIN 
        {ELEMENTARY_CATALOG}.elementary.dbt_tests tests
        ON aq.object_name = tests.unique_id
    WHERE 
        aq.dbt_project_category = 'PRODUCTION'
    GROUP BY 
        dbt_model_id
)

-- Bring it all together
SELECT
    tmm.dbt_model_id,
    price.price * (tmm.model_execution_time_hours / te.total_execution_time_hours) AS model_weekly_cost_usd
FROM 
    test_model_map tmm
LEFT JOIN 
    price ON 1 = 1
LEFT JOIN 
    total_execution_time te ON 1 = 1;
```
***
## Further information
Additional metadata from elementary tables can be added to enrich cost information. For example, models owners or business groups can be added to group costs by team.

There are similar blogs that cover estimating dbt model costs on Snowflake - this one by [SELECT](https://select.dev/posts/cost-per-query) is my favorite.