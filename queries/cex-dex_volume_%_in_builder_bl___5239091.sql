-- part of a query repo
-- query name: CEX-DEX volume % in builder blocks
-- query link: https://dune.com/queries/5239091


WITH joined_data AS (
    SELECT
        f.*,
        bed.extra_data,
        COALESCE(
            e.name,
            CASE
                WHEN from_utf8(from_hex(bed.extra_data)) LIKE '%geth%' THEN 'Vanilla Validators'
                ELSE from_utf8(from_hex(bed.extra_data))
            END
        ) AS builder_label
    FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503 f
    LEFT JOIN (
        SELECT 
            blocknumber AS block_number,
            block.extraData AS extra_data
        FROM ethereum.raw_0004
    ) bed ON bed.block_number = f.block_number
    LEFT JOIN query_3169619 e ON e.extra_data = bed.extra_data
),
weekly_totals AS (
    SELECT
        builder_label,
        DATE_TRUNC('week', block_time) AS week_start,
        SUM(volume) AS weekly_volume,
        COUNT(*) AS transaction_count
    FROM joined_data
    WHERE block_time IS NOT NULL
    GROUP BY 
        builder_label,
        DATE_TRUNC('week', block_time)
),
week_totals AS (
    SELECT 
        week_start,
        SUM(weekly_volume) AS total_week_volume
    FROM weekly_totals
    GROUP BY week_start
)
SELECT
    wt.builder_label,
    wt.week_start,
    wt.weekly_volume,
    wt.transaction_count,
    wt.weekly_volume / wto.total_week_volume AS volume_percentage
FROM weekly_totals wt
JOIN week_totals wto ON wt.week_start = wto.week_start
ORDER BY 
    wt.week_start DESC,
    wt.weekly_volume DESC;