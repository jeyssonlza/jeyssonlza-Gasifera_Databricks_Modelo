# Fase 3 — Ingesta incremental y optimización (⚙️ nivel Professional)

> Prompt a pegar tras completar la fase 2. Esta fase añade streaming real al pipeline existente.

---

```text
FASE 3 — INGESTA INCREMENTAL. Amplía el pipeline existente con dos archivos SQL
nuevos en transformations/silver.

PARTE A — AUTO LOADER:
1. Crea un Volumen de Unity Catalog en <catalog>.gasifera llamado 'raw'.
2. Genera 14 archivos JSONL diarios (una medición por línea) en
   /Volumes/<catalog>/gasifera/raw/telemetria/: 40 estaciones por día,
   campos: estacion_id, region, fecha, presion_entrada_barg (2.8-4.4, con ~8%
   de lecturas 'alerta' más bajas), caudal_m3h, temperatura_c, horas_operacion,
   estado_equipo (ok/alerta).
3. Crea transformations/silver/silver_telemetria.sql: STREAMING TABLE con
   FROM STREAM(read_files('<ruta>', format => 'json')), expectativas
   (estacion_id IS NOT NULL → DROP, presion BETWEEN 0 AND 6 → warn, caudal > 0
   → DROP) y CLUSTER BY (fecha, region).

PARTE B — AUTO CDC SCD TIPO 2:
1. Genera 3 CSV incrementales en /Volumes/<catalog>/gasifera/raw/clientes_cambios/
   con columnas: cliente_id, tipo_cliente, nombre_contacto, estado,
   fecha_cambio, operacion (INSERT/UPDATE/DELETE). Mezcla: 40 clientes ACTIVOS
   pasados a 'baja' (UPDATE), 25 clientes nuevos (INSERT, ids CLI018001+),
   10 clientes 'baja' reactivados a 'activo' (UPDATE). En los UPDATE, deja
   tipo_cliente y nombre_contacto como string vacío.
2. Añade transformations/silver/silver_clientes_cdc.sql con CUATRO capas:
   a) raw_clientes_cambios: STREAMING TABLE con read_files CSV y
      schemaHints => 'fecha_cambio DATE'.
   b) clientes_cambios_limpios: PRIVATE STREAMING TABLE con NULLIF('') y filtro
      de operaciones válidas.
   c) clientes_feed_unificado: PRIVATE STREAMING TABLE con DOS append flows:
      - 'clientes_backfill_inicial': INSERT INTO ONCE ... BY NAME leyendo
        dim_clientes EN BATCH (sin STREAM), con fecha_cambio = fecha_alta y
        operacion='INSERT'. Esto mete el estado histórico como eventos.
      - 'clientes_cambios_flow': INSERT INTO continuo desde el feed limpio.
   d) silver_clientes_scd2: AUTO CDC INTO con KEYS (cliente_id),
      IGNORE NULL UPDATES, APPLY AS DELETE WHEN operacion='DELETE',
      SEQUENCE BY fecha_cambio, COLUMNS * EXCEPT (operacion),
      STORED AS SCD TYPE 2.

PARTE C — OPTIMIZACIÓN:
- Ejecuta OPTIMIZE sobre silver_telemetria y muestra las métricas.
- Verifica el liquid clustering con SHOW TBLPROPERTIES (clusteringColumns).
- Ejecuta un DRY RUN del pipeline y luego el update. Si aparece
  DIFFERENT_DELTA_TABLE_READ_BY_STREAMING_SOURCE, explica que hay que resetear
  el checkpoint del flujo CDC y pídeme confirmación.

VERIFICACIÓN: (a) silver_telemetria = 560 filas (14×40) con fechas correctas,
(b) raw_clientes_cambios = 75 filas, (c) silver_clientes_scd2: cada cliente con
EXACTAMENTE una versión vigente (__END_AT IS NULL), los 40 dados de baja con 2
versiones (activo→baja) y los 10 reactivados con 2 versiones (baja→activo),
(d) clusteringColumns = [[fecha],[region]].
```

### Criterios de aceptación
- [ ] Auto Loader procesa cada archivo una sola vez (re-ejecutar el pipeline no duplica)
- [ ] SCD2 íntegra: 0 clientes con más de una versión vigente; historial cerrado correcto
- [ ] Liquid clustering activo y OPTIMIZE ejecutado con métricas mostradas

### Errores típicos (¡los sufrimos de verdad!)
* `IGNORE NULL UPDATES ON (col1, col2)` no parsea en SQL → usa `IGNORE NULL UPDATES` simple.
* `CREATE OR REFRESH TEMPORARY VIEW` no existe en SDP → usa `PRIVATE STREAMING TABLE`.
* Un feed CDC sin backfill deja cada cliente con UNA sola versión → el estado inicial debe entrar como eventos (`INSERT INTO ONCE`) con `fecha_cambio = fecha_alta`.
* Cambiar el fuente de un flujo CDC invalida su checkpoint → reset del checkpoint del flujo (requiere confirmación), no de la tabla.
