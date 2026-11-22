-- Capa silver: interrupciones de suministro validadas.
-- Reglas DQ aplicadas: DQ20 (fechas dentro del periodo del proyecto).
CREATE OR REFRESH MATERIALIZED VIEW silver_interrupciones (
  CONSTRAINT evento_presente EXPECT (evento_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT duracion_positiva EXPECT (duracion_min > 0) ON VIOLATION DROP ROW,
  CONSTRAINT clientes_no_negativos EXPECT (clientes_afectados >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT fecha_en_periodo EXPECT (fecha BETWEEN DATE '2024-01-01' AND DATE '2026-11-30')
)
COMMENT 'Interrupciones validadas: duracion/clientes positivos y fechas dentro del periodo del proyecto'
AS SELECT *
FROM workspace.gasifera.fact_interrupciones;
