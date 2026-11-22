-- Capa silver: metricas regulatorias AGEPAR validadas.
-- Reglas DQ aplicadas: DQ21 (pct_cumple_norma entre 0 y 100).
CREATE OR REFRESH MATERIALIZED VIEW silver_metricas_agepar (
  CONSTRAINT pct_cumple_norma_0_100 EXPECT (pct_cumple_norma BETWEEN 0 AND 100),
  CONSTRAINT saidi_no_negativo EXPECT (saidi_min >= 0),
  CONSTRAINT saifi_no_negativo EXPECT (saifi >= 0),
  CONSTRAINT cobertura_0_100 EXPECT (cobertura_pct BETWEEN 0 AND 100)
)
COMMENT 'Metricas AGEPAR validadas: porcentajes en rango 0-100 e indicadores no negativos'
AS SELECT *
FROM workspace.gasifera.fact_metricas_agepar;
