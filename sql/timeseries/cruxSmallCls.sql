#standardSQL
# Small CLS by device

CREATE TEMP FUNCTION IS_GOOD (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good / (good + needs_improvement + poor) >= 0.75
);

CREATE TEMP FUNCTION IS_NON_ZERO (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good + needs_improvement + poor > 0
);

WITH
  base AS (
  SELECT
    yyyymm,
    origin,
    device,
    
    small_cls,
    medium_cls,
    large_cls

  FROM
    `chrome-ux-report.materialized.device_summary`
  WHERE
    device IN ('desktop','phone')
    AND yyyymm >= 201905
  )

SELECT
  REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(device = 'desktop', 'desktop', 'mobile') AS client,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_GOOD(small_cls, medium_cls, large_cls), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(small_cls, medium_cls, large_cls), origin, NULL))) AS percent
FROM
  base
WHERE
  device IN ('desktop','phone')
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
