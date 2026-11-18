-- Iceberg table in the Harmony catalog: customers with their shipped revenue.
select
    c.customer_id,
    c.customer_name,
    c.country,
    c.signup_date,
    count(f.order_id) as shipped_orders,
    coalesce(sum(f.revenue), 0) as shipped_revenue
from {{ ref('stg_customers') }} as c
left join {{ ref('fct_orders') }} as f
    on f.customer_id = c.customer_id and f.status = 'shipped'
group by 1, 2, 3, 4
