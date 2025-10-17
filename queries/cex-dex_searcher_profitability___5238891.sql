-- part of a query repo
-- query name: CEX-DEX Searcher Profitability
-- query link: https://dune.com/queries/5238891


select *
from dune.rig_ef.dataset_cexdex_bot_analysis_results
where mev_bot_label != 'Graves'