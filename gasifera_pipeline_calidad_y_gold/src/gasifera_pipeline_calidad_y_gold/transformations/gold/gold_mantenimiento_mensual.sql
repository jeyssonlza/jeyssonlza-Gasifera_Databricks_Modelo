-- Capa gold: mantenimiento por periodo y tipo de orden.
-- El periodo se deriva de fecha_programada (la tabla fuente no trae columna periodo).
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_mantenimiento_mensual
COMMENT 'Mantenimiento mensual por tipo de orden: ordenes, completadas, % en plazo, horas y costo'
AS SELECT
  CAST(date_trunc('MM', fecha_programada) AS DATE) AS periodo,
  tipo_orden,
  COUNT(*) AS ordenes,
  SUM(CASE WHEN estado = 'completada' THEN 1 ELSE 0 END) AS completadas,
  ROUND(AVG(CASE WHEN cumple_plazo THEN 1.0 ELSE 0.0 END) * 100, 1) AS pct_en_plazo,
  SUM(horas_hombre) AS horas_hombre,
  SUM(costo_total_usd) AS costo_total_usd
FROM silver_mantenimiento
GROUP BY CAST(date_trunc('MM', fecha_programada) AS DATE), tipo_orden;
