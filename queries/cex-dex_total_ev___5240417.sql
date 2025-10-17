-- part of a query repo
-- query name: CEX-DEX Total EV
-- query link: https://dune.com/queries/5240417


SELECT 
    mev_bot_label,
    total_volume,
    total_revenue,
    builder_payments,
    total_pnl,
    median_revenue,
    median_pnl,
    median_profit_margin,
    median_volume,
    median_gross_return
FROM dune.rig_ef.dataset_cexdex_bot_analysis_results

UNION ALL

SELECT 
    'Total' AS mev_bot_label,
    SUM(total_volume) AS total_volume,
    SUM(total_revenue) AS total_revenue,
    NULL AS builder_payments,
    NULL AS total_pnl,
    NULL AS median_revenue,
    NULL AS median_pnl,
    NULL AS median_profit_margin,
    NULL AS median_volume,
    NULL AS median_gross_return
FROM dune.rig_ef.dataset_cexdex_bot_analysis_results

UNION ALL

SELECT 
    'Top 3' AS mev_bot_label,
    SUM(total_volume) AS total_volume,
    SUM(total_revenue) AS total_revenue,
    NULL AS builder_payments,
    NULL AS total_pnl,
    NULL AS median_revenue,
    NULL AS median_pnl,
    NULL AS median_profit_margin,
    NULL AS median_volume,
    NULL AS median_gross_return
FROM dune.rig_ef.dataset_cexdex_bot_analysis_results
WHERE mev_bot_label IN ('SCP', 'Wintermute', 'Kayle')

ORDER BY 
    CASE 
        WHEN mev_bot_label = 'Total' THEN 1 
        WHEN mev_bot_label = 'Top 3' THEN 2 
        ELSE 3 
    END,
    total_volume DESC;
