-- Capa silver: SCD Tipo 2 de clientes via Auto CDC (Professional).
-- Feed de cambios llega como CSV incrementales a /Volumes/workspace/gasifera/raw/clientes_cambios.

-- 1) Ingesta incremental del feed de cambios (Auto Loader sobre CSV)
CREATE OR REFRESH STREAMING TABLE raw_clientes_cambios
COMMENT 'Feed crudo de cambios de clientes: INSERT/UPDATE/DELETE por lote'
AS SELECT *
FROM STREAM(read_files(
  '/Volumes/workspace/gasifera/raw/clientes_cambios',
  format => 'csv',
  schemaHints => 'fecha_cambio DATE'
));

-- 2) Limpieza previa al CDC: vacios -> NULL y filtro de operaciones validas
--    (PRIVATE: tabla de staging solo dentro del pipeline, no se publica en UC)
CREATE OR REFRESH PRIVATE STREAMING TABLE clientes_cambios_limpios AS
SELECT
  cliente_id,
  NULLIF(tipo_cliente, '') AS tipo_cliente,
  NULLIF(nombre_contacto, '') AS nombre_contacto,
  estado,
  CAST(fecha_cambio AS DATE) AS fecha_cambio,
  operacion
FROM STREAM(raw_clientes_cambios)
WHERE cliente_id IS NOT NULL
  AND operacion IN ('INSERT', 'UPDATE', 'DELETE');

-- 3) Unificacion del feed: backfill inicial (ONCE, batch) + cambios continuos (Append Flows)
CREATE OR REFRESH PRIVATE STREAMING TABLE clientes_feed_unificado;

CREATE FLOW clientes_backfill_inicial AS INSERT INTO ONCE clientes_feed_unificado BY NAME
SELECT
  cliente_id,
  tipo_cliente,
  nombre_contacto,
  estado,
  CAST(fecha_alta AS DATE) AS fecha_cambio,
  'INSERT' AS operacion
FROM workspace.gasifera.dim_clientes;

CREATE FLOW clientes_cambios_flow AS INSERT INTO clientes_feed_unificado BY NAME
SELECT
  cliente_id,
  tipo_cliente,
  nombre_contacto,
  estado,
  fecha_cambio,
  operacion
FROM STREAM(clientes_cambios_limpios);

-- 4) Auto CDC con historial (SCD Tipo 2): __START_AT / __END_AT por fecha_cambio
CREATE OR REFRESH STREAMING TABLE silver_clientes_scd2;

CREATE FLOW clientes_cdc_flow AS AUTO CDC INTO silver_clientes_scd2
FROM STREAM(clientes_feed_unificado)
KEYS (cliente_id)
IGNORE NULL UPDATES
APPLY AS DELETE WHEN operacion = 'DELETE'
SEQUENCE BY fecha_cambio
COLUMNS * EXCEPT (operacion)
STORED AS SCD TYPE 2;
