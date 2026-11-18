select
    cast(customer_id as integer) as customer_id,
    trim(name) as customer_name,
    upper(trim(country)) as country,
    cast(signup_date as date) as signup_date
from {{ source('raw', 'customers') }}
