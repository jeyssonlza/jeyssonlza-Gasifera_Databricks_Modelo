-- Capa gold: consumo agregado por periodo, region y tipo de cliente.
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_consumo_mensual
COMMENT 'Consumo mensual agregado: clientes, volumen, energia, facturacion e impago por periodo/region/tipo_cliente'
AS SELECT
  periodo,
  region,
  tipo_cliente,
  COUNT(*) AS clientes,
  ROUND(SUM(volumen_m3), 1) AS volumen_m3,
  ROUND(SUM(energia_kwh), 1) AS energia_kwh,
  ROUND(SUM(monto_facturado_usd), 2) AS facturacion_usd,
  ROUND(AVG(CASE WHEN factura_impaga THEN 1.0 ELSE 0.0 END) * 100, 1) AS pct_impago
FROM silver_consumo_mensual
GROUP BY periodo, region, tipo_cliente;
