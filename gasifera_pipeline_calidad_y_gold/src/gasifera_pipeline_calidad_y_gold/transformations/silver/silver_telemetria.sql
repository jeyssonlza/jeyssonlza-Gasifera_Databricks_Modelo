-- Capa silver: ingesta INCREMENTAL de telemetria de estaciones con Auto Loader (read_files + STREAM).
-- Cada archivo JSONL nuevo en /Volumes/workspace/gasifera/raw/telemetria se procesa una sola vez.
-- Optimizacion: liquid clustering por fecha y region.
CREATE OR REFRESH STREAMING TABLE silver_telemetria (
  CONSTRAINT estacion_presente EXPECT (estacion_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT presion_fisica EXPECT (presion_entrada_barg BETWEEN 0 AND 6),
  CONSTRAINT caudal_positivo EXPECT (caudal_m3h > 0) ON VIOLATION DROP ROW
)
CLUSTER BY (fecha, region)
COMMENT 'Telemetria diaria de estaciones ingerida incrementalmente con Auto Loader'
AS SELECT
  estacion_id,
  region,
  CAST(fecha AS DATE) AS fecha,
  CAST(presion_entrada_barg AS DOUBLE) AS presion_entrada_barg,
  CAST(caudal_m3h AS DOUBLE) AS caudal_m3h,
  CAST(temperatura_c AS DOUBLE) AS temperatura_c,
  CAST(horas_operacion AS DOUBLE) AS horas_operacion,
  estado_equipo
FROM STREAM(read_files(
  '/Volumes/workspace/gasifera/raw/telemetria',
  format => 'json'
));
