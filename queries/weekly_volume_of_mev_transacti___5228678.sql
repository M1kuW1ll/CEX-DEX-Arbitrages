-- part of a query repo
-- query name: Weekly Volume of MEV Transactions 202308-202503
-- query link: https://dune.com/queries/5228678


WITH cex_dex_daily_volume AS (
    SELECT 
        date_trunc('week', block_time) as date,
        SUM(volume) as cex_dex_trade_volume
    FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503
    WHERE volume IS NOT NULL
    GROUP BY date_trunc('week', block_time)
),

cex_dex_total AS (
    SELECT SUM(volume) as total_cex_dex_volume
    FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503
    WHERE volume IS NOT NULL
),

atomic_arb_daily_volume AS (
    SELECT 
        date_trunc('week', block_time) AS date,
        SUM(amount_usd) AS atomic_arb_volume
    FROM dex.atomic_arbitrages
    WHERE blockchain = 'ethereum'
        AND block_time > date('2023-08-08')
        AND block_time < date_trunc('week', date('2025-03-08'))
    GROUP BY 1
),


sandwich_data AS (
    SELECT date_trunc('week', t.block_time) AS time
    , t.tx_hash
    , CASE WHEN MAX(st.block_time) IS NOT NULL THEN 'Sandwiched'
        WHEN MAX(s.block_time) IS NOT NULL THEN 'Sandwich'
        ELSE 'Other' END AS user_type,
        SUM(t.amount_usd) AS volume
    FROM dex.trades t
    LEFT JOIN dex.sandwiches s ON s.blockchain = 'ethereum'
        AND s.block_time = t.block_time
        AND s.tx_hash = t.tx_hash
        AND s.project_contract_address = t.project_contract_address
        AND s.evt_index = t.evt_index
        AND s.block_time > date('2023-08-08')
        AND s.block_time < date_trunc('week', date('2025-03-08'))
    LEFT JOIN dex.sandwiched st ON st.blockchain = 'ethereum'
        AND st.block_time = t.block_time
        AND st.tx_hash = t.tx_hash
        AND st.project_contract_address = t.project_contract_address
        AND st.evt_index = t.evt_index
        AND st.block_time > date('2023-08-08')
        AND st.block_time < date_trunc('week', date('2025-03-08'))
    WHERE t.blockchain = 'ethereum'
    AND t.block_time > date('2023-08-08')
    AND t.block_time < date_trunc('week', date('2025-03-08'))
    GROUP BY 1, 2
),

sandwich_daily_volume AS (
    SELECT
        time as date,
        SUM(volume) AS sandwich_volume
    FROM sandwich_data
    WHERE user_type = 'Sandwich'
    GROUP BY 1
)

   

SELECT 
    COALESCE(c.date, a.date, s.date) as date,
    COALESCE(c.cex_dex_trade_volume, 0) as "CEX-DEX Arb",
    COALESCE(a.atomic_arb_volume, 0) as "Atomic Arb",
    COALESCE(s.sandwich_volume, 0) as "Sandwich"
FROM cex_dex_daily_volume c
FULL OUTER JOIN atomic_arb_daily_volume a ON c.date = a.date
FULL OUTER JOIN sandwich_daily_volume s ON COALESCE(c.date, a.date) = s.date
WHERE COALESCE(c.date, a.date, s.date) IS NOT NULL

UNION ALL

-- Total row
SELECT 
    NULL as date,
    t.total_cex_dex_volume as "CEX-DEX Arb",
    0 as "Atomic Arb",
    0 as "Sandwich"
FROM cex_dex_total t

ORDER BY date DESC NULLS FIRST;