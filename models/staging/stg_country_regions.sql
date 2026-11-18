-- Personal raw data (seed in raw.<your schema>_raw), cleaned like the shared raw tables.
select
    upper(trim(country)) as country,
    trim(country_name) as country_name,
    trim(region) as region
from {{ ref('country_regions') }}
