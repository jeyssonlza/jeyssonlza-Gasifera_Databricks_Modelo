-- Capa silver: mediciones de presion validadas.
-- Reglas DQ aplicadas: DQ16 (presion_barg > 0).
CREATE OR REFRESH MATERIALIZED VIEW silver_presiones (
  CONSTRAINT estacion_presente EXPECT (estacion_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT presion_positiva EXPECT (presion_barg > 0) ON VIOLATION DROP ROW
)
COMMENT 'Mediciones de presion validadas: presion estrictamente positiva (fuera_de_rango es un dato legitimo de operacion)'
AS SELECT *
FROM workspace.gasifera.fact_presiones;
