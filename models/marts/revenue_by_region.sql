-- Iceberg table in the Harmony catalog: shipped revenue per region. Joins the shared raw layer (through
-- dim_customers) with your own raw layer (the country_regions seed).
select
    r.region,
    count(distinct c.customer_id) as customers,
    sum(c.shipped_orders) as shipped_orders,
    sum(c.shipped_revenue) as shipped_revenue
from {{ ref('dim_customers') }} as c
join {{ ref('stg_country_regions') }} as r on r.country = c.country
group by 1
