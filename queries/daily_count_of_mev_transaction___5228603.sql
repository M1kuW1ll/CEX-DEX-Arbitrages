-- part of a query repo
-- query name: Daily Count of MEV Transactions 202308-202503
-- query link: https://dune.com/queries/5228603


WITH cex_dex_daily AS (
    SELECT 
        DATE(block_time) as date,
        COUNT(*) as cex_dex_trade_count
    FROM dune.rig_ef.result_main_cex_dex_transactions_202308_202503
    WHERE volume IS NOT NULL
    GROUP BY DATE(block_time)
),

atomic_arb_daily AS (
    SELECT 
        date_trunc('day', block_time) AS date,
        COUNT(DISTINCT tx_hash) AS atomic_arb_count
    FROM dex.atomic_arbitrages
    WHERE blockchain = 'ethereum'
        AND block_time > date('2023-08-08')
        AND block_time < date_trunc('day', date('2025-03-08'))
    GROUP BY 1
),

sandwich_data AS (
    SELECT date_trunc('day', t.block_time) AS time
    , t.tx_hash
    , CASE WHEN MAX(st.block_time) IS NOT NULL THEN 'Sandwiched'
        WHEN MAX(s.block_time) IS NOT NULL THEN 'Sandwich'
        ELSE 'Other' END AS user_type
    FROM dex.trades t
    LEFT JOIN dex.sandwiches s ON s.blockchain = 'ethereum'
        AND s.block_time = t.block_time
        AND s.tx_hash = t.tx_hash
        AND s.project_contract_address = t.project_contract_address
        AND s.evt_index = t.evt_index
        AND s.block_time > date('2023-08-08')
        AND s.block_time < date_trunc('day', date('2025-03-08'))
    LEFT JOIN dex.sandwiched st ON st.blockchain = 'ethereum'
        AND st.block_time = t.block_time
        AND st.tx_hash = t.tx_hash
        AND st.project_contract_address = t.project_contract_address
        AND st.evt_index = t.evt_index
        AND st.block_time > date('2023-08-08')
        AND st.block_time < date_trunc('day', date('2025-03-08'))
    WHERE t.blockchain = 'ethereum'
    AND t.block_time > date('2023-08-08')
    AND t.block_time < date_trunc('day', date('2025-03-08'))
    GROUP BY 1, 2
),

sandwich_daily AS (
    SELECT
        time as date,
        COUNT(*) AS sandwich_transactions,
        COUNT(CASE WHEN user_type = 'Sandwiched' THEN 1 END) AS sandwiched_transactions
    FROM sandwich_data
    WHERE user_type IN ('Sandwich', 'Sandwiched')
    GROUP BY 1
)

SELECT 
    COALESCE(c.date, a.date, s.date) as date,
    
    -- Transaction counts by MEV type
    COALESCE(c.cex_dex_trade_count, 0) as "CEX-DEX Arb",
    COALESCE(a.atomic_arb_count, 0) as "Atomic Arb",
    COALESCE(s.sandwich_transactions, 0) as "Sandwich"

   

FROM cex_dex_daily c
FULL OUTER JOIN atomic_arb_daily a ON c.date = a.date
FULL OUTER JOIN sandwich_daily s ON COALESCE(c.date, a.date) = s.date
WHERE COALESCE(c.date, a.date, s.date) IS NOT NULL
ORDER BY date DESC;