-- Iceberg table in the Harmony catalog: one row per order line, with its revenue.
select
    o.order_id,
    o.order_date,
    o.customer_id,
    o.product_id,
    p.category,
    o.quantity,
    p.unit_price,
    cast(o.quantity * p.unit_price as decimal(14, 2)) as revenue,
    o.status
from {{ ref('stg_orders') }} as o
join {{ ref('stg_products') }} as p on p.product_id = o.product_id
