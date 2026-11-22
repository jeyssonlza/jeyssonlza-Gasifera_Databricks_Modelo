-- Capa gold: operaciones por periodo y region (interrupciones + seguridad + presiones + calidad).
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_operaciones_mensual
COMMENT 'Operaciones mensuales por region: interrupciones, incidentes de seguridad, presiones y calidad del gas'
AS
WITH interr AS (
  -- Solo interrupciones NO programadas: los mantenimientos programados no cuentan
  -- como fallas de continuidad (criterio regulatorio, consistente con el SAIDI de AGEPAR).
  SELECT periodo, region,
         COUNT(*) AS interrupciones,
         SUM(duracion_min * clientes_afectados) AS cliente_minutos_interrumpidos,
         SUM(clientes_afectados) AS clientes_afectados,
         ROUND(AVG(duracion_min), 1) AS duracion_media_min,
         ROUND(SUM(compensacion_usd), 2) AS compensacion_usd
  FROM silver_interrupciones
  WHERE NOT programada
  GROUP BY periodo, region
),
seg AS (
  SELECT periodo, region,
         COUNT(*) AS incidentes_seguridad,
         SUM(heridos) AS heridos,
         SUM(evacuados) AS evacuados,
         ROUND(SUM(volumen_perdido_m3), 1) AS volumen_perdido_m3,
         SUM(costo_reparacion_usd) AS costo_incidentes_usd
  FROM silver_incidentes_seguridad
  GROUP BY periodo, region
),
pres AS (
  SELECT CAST(date_trunc('MM', fecha) AS DATE) AS periodo, region,
         COUNT(*) AS mediciones,
         ROUND(AVG(CASE WHEN fuera_de_rango THEN 1.0 ELSE 0.0 END) * 100, 2) AS pct_presiones_fuera_rango
  FROM silver_presiones
  GROUP BY CAST(date_trunc('MM', fecha) AS DATE), region
),
cal AS (
  SELECT periodo, region,
         ROUND(AVG(pci_kwh_m3), 2) AS pci_promedio,
         ROUND(AVG(CASE WHEN cumple_norma THEN 1.0 ELSE 0.0 END) * 100, 1) AS pct_cumple_norma_gas
  FROM silver_calidad_gas
  GROUP BY periodo, region
)
SELECT
  COALESCE(i.periodo, s.periodo, p.periodo, cal.periodo) AS periodo,
  COALESCE(i.region, s.region, p.region, cal.region) AS region,
  COALESCE(i.interrupciones, 0) AS interrupciones,
  COALESCE(i.cliente_minutos_interrumpidos, 0) AS cliente_minutos_interrumpidos,
  COALESCE(i.clientes_afectados, 0) AS clientes_afectados,
  COALESCE(i.duracion_media_min, 0) AS duracion_media_min,
  COALESCE(i.compensacion_usd, 0) AS compensacion_usd,
  COALESCE(s.incidentes_seguridad, 0) AS incidentes_seguridad,
  COALESCE(s.heridos, 0) AS heridos,
  COALESCE(s.evacuados, 0) AS evacuados,
  COALESCE(s.volumen_perdido_m3, 0) AS volumen_perdido_m3,
  COALESCE(s.costo_incidentes_usd, 0) AS costo_incidentes_usd,
  COALESCE(p.mediciones, 0) AS mediciones,
  COALESCE(p.pct_presiones_fuera_rango, 0) AS pct_presiones_fuera_rango,
  COALESCE(cal.pci_promedio, 0) AS pci_promedio,
  COALESCE(cal.pct_cumple_norma_gas, 0) AS pct_cumple_norma_gas
FROM interr i
FULL OUTER JOIN seg s ON i.periodo = s.periodo AND i.region = s.region
FULL OUTER JOIN pres p ON COALESCE(i.periodo, s.periodo) = p.periodo AND COALESCE(i.region, s.region) = p.region
FULL OUTER JOIN cal ON COALESCE(i.periodo, s.periodo, p.periodo) = cal.periodo
                     AND COALESCE(i.region, s.region, p.region) = cal.region;
