-- Capa silver: atencion al cliente validada.
-- Reglas DQ aplicadas: DQ03 (ticket_id unico), DQ17 (satisfaccion entre 1 y 5).
CREATE OR REFRESH MATERIALIZED VIEW silver_atencion_clientes (
  CONSTRAINT ticket_presente EXPECT (ticket_id IS NOT NULL AND cliente_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT satisfaccion_1_a_5 EXPECT (satisfaccion BETWEEN 1 AND 5) ON VIOLATION DROP ROW,
  CONSTRAINT resolucion_no_negativa EXPECT (horas_resolucion >= 0),
  CONSTRAINT dominio_prioridad EXPECT (prioridad IN ('critica', 'alta', 'media', 'baja'))
)
COMMENT 'Atencion al cliente validada: ticket unico, satisfaccion 1-5, resolucion no negativa'
AS SELECT *
FROM workspace.gasifera.fact_atencion_clientes
QUALIFY row_number() OVER (PARTITION BY ticket_id ORDER BY fecha) = 1;
