-- part of a query repo
-- query name: CEX-DEX Volume per bot
-- query link: https://dune.com/queries/5228809


WITH weekly_bot_stats AS (
    SELECT 
        date_trunc('week', block_time) as week_start,
        COALESCE(mev_bot_label, 'Unlabeled') as mev_bot_label,
        SUM(volume) as weekly_volume_usd,
        COUNT(*) as transaction_count,
        SUM(mev_value) as weekly_mev_value
    FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503
    WHERE volume IS NOT NULL
    GROUP BY 1, 2
),
bot_rankings AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY week_start ORDER BY weekly_volume_usd DESC) as volume_rank,
        ROUND(weekly_volume_usd * 100.0 / SUM(weekly_volume_usd) OVER (PARTITION BY week_start), 2) as pct_of_weekly_volume
    FROM weekly_bot_stats
)
SELECT 
    week_start,
    mev_bot_label,
    weekly_volume_usd,
    transaction_count,
    weekly_mev_value,
    volume_rank,
    pct_of_weekly_volume
FROM bot_rankings
WHERE volume_rank <= 20  
ORDER BY 
    week_start DESC,
    volume_rank ASC;