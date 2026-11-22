-- Capa gold: vision 360 grados por cliente (consumo + atencion + riesgo de baja).
-- riesgo_baja = estado 'baja' o meses con consumo <= 3.
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_clientes_360
COMMENT 'Clientes 360: consumo, atencion y flag riesgo_baja (estado baja o <= 3 meses de consumo)'
AS
WITH consumo AS (
  SELECT
    cliente_id,
    COUNT(*) AS meses_con_consumo,
    ROUND(SUM(volumen_m3), 1) AS volumen_total_m3,
    ROUND(AVG(volumen_m3), 1) AS consumo_medio_m3,
    ROUND(SUM(monto_facturado_usd), 2) AS facturacion_total_usd,
    MAX(CASE WHEN factura_impaga THEN 1 ELSE 0 END) AS tuvo_impago
  FROM silver_consumo_mensual
  GROUP BY cliente_id
),
atencion AS (
  SELECT
    cliente_id,
    COUNT(*) AS tickets,
    ROUND(AVG(CASE WHEN sla_cumplido THEN 1.0 ELSE 0.0 END) * 100, 1) AS pct_sla,
    ROUND(AVG(satisfaccion), 2) AS satisfaccion_media
  FROM silver_atencion_clientes
  GROUP BY cliente_id
)
SELECT
  c.cliente_id,
  c.tipo_cliente,
  c.region,
  c.estado,
  ROUND(MONTHS_BETWEEN(DATE '2026-11-01', c.fecha_alta), 1) AS antiguedad_meses,
  COALESCE(cs.meses_con_consumo, 0) AS meses_con_consumo,
  COALESCE(cs.volumen_total_m3, 0) AS volumen_total_m3,
  COALESCE(cs.consumo_medio_m3, 0) AS consumo_medio_m3,
  COALESCE(cs.facturacion_total_usd, 0) AS facturacion_total_usd,
  COALESCE(cs.tuvo_impago, 0) AS tuvo_impago,
  COALESCE(a.tickets, 0) AS tickets,
  COALESCE(a.pct_sla, 100.0) AS pct_sla,
  COALESCE(a.satisfaccion_media, 0.0) AS satisfaccion_media,
  (c.estado = 'baja' OR COALESCE(cs.meses_con_consumo, 0) <= 3) AS riesgo_baja
FROM workspace.gasifera.dim_clientes c
LEFT JOIN consumo cs ON c.cliente_id = cs.cliente_id
LEFT JOIN atencion a ON c.cliente_id = a.cliente_id;
