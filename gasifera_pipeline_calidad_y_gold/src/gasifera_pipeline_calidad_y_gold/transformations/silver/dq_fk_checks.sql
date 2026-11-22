-- Chequeos de integridad referencial (DQ06-DQ11) y de negocio (DQ22) del catalogo dq_reglas.
-- Vistas materializadas PRIVADAS: solo viven dentro del pipeline; quedan vacias mientras los datos
-- son validos y fallan el update (FAIL UPDATE) si aparece algun huerfano o violacion.

-- DQ06: todo cliente_id de fact_consumo_mensual existe en dim_clientes
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_consumo_clientes (
  CONSTRAINT fk_consumo_clientes EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.cliente_id, false AS fk_valida
FROM workspace.gasifera.fact_consumo_mensual f
LEFT ANTI JOIN workspace.gasifera.dim_clientes c ON f.cliente_id = c.cliente_id
WHERE f.cliente_id IS NOT NULL;

-- DQ07: todo cliente_id de fact_atencion_clientes existe en dim_clientes
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_atencion_clientes (
  CONSTRAINT fk_atencion_clientes EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.cliente_id, false AS fk_valida
FROM workspace.gasifera.fact_atencion_clientes f
LEFT ANTI JOIN workspace.gasifera.dim_clientes c ON f.cliente_id = c.cliente_id
WHERE f.cliente_id IS NOT NULL;

-- DQ08: todo cliente_id de fact_conexiones existe en dim_clientes
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_conexiones_clientes (
  CONSTRAINT fk_conexiones_clientes EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.cliente_id, false AS fk_valida
FROM workspace.gasifera.fact_conexiones f
LEFT ANTI JOIN workspace.gasifera.dim_clientes c ON f.cliente_id = c.cliente_id
WHERE f.cliente_id IS NOT NULL;

-- DQ09: todo empleado_id de fact_mantenimiento existe en dim_empleados
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_mantenimiento_empleados (
  CONSTRAINT fk_mantenimiento_empleados EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.empleado_id, false AS fk_valida
FROM workspace.gasifera.fact_mantenimiento f
LEFT ANTI JOIN workspace.gasifera.dim_empleados e ON f.empleado_id = e.empleado_id
WHERE f.empleado_id IS NOT NULL;

-- DQ10: todo estacion_id de fact_presiones existe en dim_estaciones
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_presiones_estaciones (
  CONSTRAINT fk_presiones_estaciones EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.estacion_id, false AS fk_valida
FROM workspace.gasifera.fact_presiones f
LEFT ANTI JOIN workspace.gasifera.dim_estaciones e ON f.estacion_id = e.estacion_id
WHERE f.estacion_id IS NOT NULL;

-- DQ11: todo estacion_id de fact_calidad_gas existe en dim_estaciones
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_fk_calidad_estaciones (
  CONSTRAINT fk_calidad_estaciones EXPECT (fk_valida) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT f.estacion_id, false AS fk_valida
FROM workspace.gasifera.fact_calidad_gas f
LEFT ANTI JOIN workspace.gasifera.dim_estaciones e ON f.estacion_id = e.estacion_id
WHERE f.estacion_id IS NOT NULL;

-- DQ22: clientes dados de baja no deben registrar consumo > 0
CREATE OR REFRESH PRIVATE MATERIALIZED VIEW dq_baja_sin_consumo (
  CONSTRAINT baja_sin_consumo EXPECT (violaciones = 0) ON VIOLATION FAIL UPDATE
)
REFRESH POLICY INCREMENTAL
AS SELECT COUNT(*) AS violaciones
FROM workspace.gasifera.dim_clientes c
JOIN workspace.gasifera.fact_consumo_mensual f ON c.cliente_id = f.cliente_id
WHERE c.estado = 'baja' AND f.volumen_m3 > 0;
