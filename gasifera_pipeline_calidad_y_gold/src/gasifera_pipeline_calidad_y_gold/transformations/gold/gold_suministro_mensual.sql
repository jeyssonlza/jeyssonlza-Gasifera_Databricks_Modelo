-- Capa gold: suministro por periodo (contratos vs entregas y penalidades).
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_suministro_mensual
COMMENT 'Suministro mensual: proveedores, contratado vs entregado, cumplimiento, precio medio y penalidades'
AS SELECT
  periodo,
  COUNT(DISTINCT proveedor) AS proveedores,
  SUM(volumen_contratado_m3) AS contratado_m3,
  SUM(volumen_entregado_m3) AS entregado_m3,
  ROUND(SUM(volumen_entregado_m3) / SUM(volumen_contratado_m3) * 100, 1) AS pct_cumplimiento,
  ROUND(AVG(precio_usd_m3), 3) AS precio_medio_usd_m3,
  SUM(penalidad_usd) AS penalidades_usd
FROM silver_compras_suministro
GROUP BY periodo;
