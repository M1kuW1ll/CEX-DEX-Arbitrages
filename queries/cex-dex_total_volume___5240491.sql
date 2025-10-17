-- part of a query repo
-- query name: CEX-DEX Total Volume
-- query link: https://dune.com/queries/5240491


SELECT 
   'Total' as mev_bot_label,
   SUM(volume) as volume
FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503

UNION ALL

SELECT 
   'Top 3' as mev_bot_label,
   SUM(volume) as volume
FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503
WHERE mev_bot_label IN ('SCP', 'Wintermute', 'Kayle');