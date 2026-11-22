-- Capa silver: metricas ambientales validadas.
CREATE OR REFRESH MATERIALIZED VIEW silver_ambiental (
  CONSTRAINT emisiones_no_negativas EXPECT (ch4_fugitivo_ton >= 0 AND co2_operaciones_ton >= 0),
  CONSTRAINT energia_no_negativa EXPECT (energia_consumida_kwh >= 0),
  CONSTRAINT agua_no_negativa EXPECT (agua_consumida_m3 >= 0)
)
COMMENT 'Metricas ambientales validadas: emisiones, energia y agua no negativas'
AS SELECT *
FROM workspace.gasifera.fact_ambiental;
