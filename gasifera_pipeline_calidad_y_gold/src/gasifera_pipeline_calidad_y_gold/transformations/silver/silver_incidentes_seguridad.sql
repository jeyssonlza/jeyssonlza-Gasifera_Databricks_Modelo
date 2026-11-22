-- Capa silver: incidentes de seguridad validados.
CREATE OR REFRESH MATERIALIZED VIEW silver_incidentes_seguridad (
  CONSTRAINT incidente_presente EXPECT (incidente_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT dominio_gravedad EXPECT (gravedad IN ('leve', 'moderada', 'grave', 'critica')) ON VIOLATION DROP ROW,
  CONSTRAINT dominio_tipo EXPECT (tipo IN ('fuga', 'falla_medidor', 'rotura_tercero', 'incendio', 'dano_ambiental')),
  CONSTRAINT respuesta_no_negativa EXPECT (tiempo_respuesta_min >= 0)
)
COMMENT 'Incidentes de seguridad validados: dominios de gravedad/tipo y tiempos de respuesta no negativos'
AS SELECT *
FROM workspace.gasifera.fact_incidentes_seguridad;
