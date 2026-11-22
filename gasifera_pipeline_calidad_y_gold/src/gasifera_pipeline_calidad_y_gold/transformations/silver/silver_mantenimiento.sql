-- Capa silver: ordenes de mantenimiento validadas.
-- Reglas DQ aplicadas: DQ04 (orden_id unico), horas y costos coherentes.
CREATE OR REFRESH MATERIALIZED VIEW silver_mantenimiento (
  CONSTRAINT orden_presente EXPECT (orden_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT horas_positivas EXPECT (horas_hombre > 0),
  CONSTRAINT costo_coherente EXPECT (ABS(costo_total_usd - costo_mano_obra_usd - costo_materiales_usd) <= 1),
  CONSTRAINT dominio_estado EXPECT (estado IN ('completada', 'en_proceso', 'cancelada')),
  CONSTRAINT dominio_tipo_orden EXPECT (tipo_orden IN ('preventivo', 'correctivo', 'predictivo'))
)
COMMENT 'Mantenimiento validado: orden unica, costos coherentes y dominios validos'
AS SELECT *
FROM workspace.gasifera.fact_mantenimiento
QUALIFY row_number() OVER (PARTITION BY orden_id ORDER BY fecha_programada) = 1;
