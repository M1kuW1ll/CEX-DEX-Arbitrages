-- part of a query repo
-- query name: Block Builder Production %
-- query link: https://dune.com/queries/5234221


with ranked_builders as (
    select 
        date_trunc('week', blockdate) as week_start,
        coalesce(name, case when from_utf8(from_hex(r.block.extraData)) like '%geth%' then 'Vanilla Validators' 
                        else from_utf8(from_hex(r.block.extraData)) end
                        ) as builder_label,
       count(blocknumber) as block_ct,
       max(blocknumber) as latest_block_per_day,
       row_number() over (partition by date_trunc('week', blockdate) order by count(blocknumber) desc) as rn
    from ethereum.raw_0004 r
    left join query_3169619 e on e.extra_data = r.block.extraData-- builder extra data labels
    where blockdate> date('2023-08-07')
    and blockdate < date('2025-03-08')
    group by 1, 2
)

select 
    week_start,
    builder_label,
    block_ct,
    latest_block_per_day
from ranked_builders
where rn <= 15
order by
    week_start DESC,
    rn ASC;