-- Capa gold: finanzas por periodo y tipo de gasto (plan vs real).
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_finanzas_mensual
COMMENT 'Finanzas mensuales por tipo de gasto (CAPEX/OPEX): plan, real y desvio porcentual'
AS SELECT
  periodo,
  tipo_gasto,
  SUM(monto_plan_usd) AS plan_usd,
  SUM(monto_real_usd) AS real_usd,
  ROUND((SUM(monto_real_usd) - SUM(monto_plan_usd)) / SUM(monto_plan_usd) * 100, 1) AS desvio_pct
FROM silver_finanzas
GROUP BY periodo, tipo_gasto;
