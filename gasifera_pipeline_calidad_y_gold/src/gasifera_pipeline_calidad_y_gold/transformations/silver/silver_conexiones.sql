-- Capa silver: conexiones nuevas validadas.
CREATE OR REFRESH MATERIALIZED VIEW silver_conexiones (
  CONSTRAINT solicitud_presente EXPECT (solicitud_id IS NOT NULL AND cliente_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT dias_no_negativos EXPECT (dias_tramitacion >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT dominio_estado EXPECT (estado IN ('conectada', 'en_tramite', 'rechazada'))
)
COMMENT 'Conexiones nuevas validadas: claves presentes, dias no negativos y dominio de estado'
AS SELECT *
FROM workspace.gasifera.fact_conexiones;
