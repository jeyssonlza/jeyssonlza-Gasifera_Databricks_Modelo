-- Capa silver: compras de suministro validadas.
CREATE OR REFRESH MATERIALIZED VIEW silver_compras_suministro (
  CONSTRAINT volumenes_no_negativos EXPECT (volumen_contratado_m3 >= 0 AND volumen_entregado_m3 >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT precio_positivo EXPECT (precio_usd_m3 > 0),
  CONSTRAINT entregado_sostenible EXPECT (volumen_entregado_m3 <= 1.5 * volumen_contratado_m3)
)
COMMENT 'Compras de suministro validadas: volumenes/precios coherentes y penalidades consistente con deficit'
AS SELECT *
FROM workspace.gasifera.fact_compras_suministro;
