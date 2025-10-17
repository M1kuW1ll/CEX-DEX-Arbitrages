-- part of a query repo
-- query name: CEX-DEX Weekly EV
-- query link: https://dune.com/queries/5240277


WITH all_weeks AS (
  SELECT DISTINCT week_start
  FROM dune.rig_ef.dataset_cexdex_weekly_ev
),
all_bots AS (
  SELECT DISTINCT mev_bot_label
  FROM dune.rig_ef.dataset_cexdex_weekly_ev
),
calendar AS (
  SELECT 
    b.mev_bot_label,
    w.week_start
  FROM all_bots b
  CROSS JOIN all_weeks w
),
joined AS (
  SELECT 
    c.mev_bot_label,
    c.week_start,
    COALESCE(d.weekly_ev, 0) AS weekly_ev
  FROM calendar c
  LEFT JOIN dune.rig_ef.dataset_cexdex_weekly_ev d
    ON c.mev_bot_label = d.mev_bot_label AND c.week_start = d.week_start
),
final AS (
  SELECT
    mev_bot_label,
    week_start,
    weekly_ev,
    SUM(weekly_ev) OVER (
      PARTITION BY mev_bot_label
      ORDER BY week_start
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_ev
  FROM joined
)
SELECT *
FROM final
ORDER BY cumulative_ev DESC;
