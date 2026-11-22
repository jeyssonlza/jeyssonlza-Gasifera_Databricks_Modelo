-- Capa silver: finanzas (CAPEX/OPEX plan vs real) validadas.
CREATE OR REFRESH MATERIALIZED VIEW silver_finanzas (
  CONSTRAINT montos_no_negativos EXPECT (monto_plan_usd >= 0 AND monto_real_usd >= 0),
  CONSTRAINT desvio_coherente EXPECT (ABS(desvio_pct) < 100)
)
COMMENT 'Finanzas validadas: montos no negativos y desvios coherentes'
AS SELECT *
FROM workspace.gasifera.fact_finanzas;
