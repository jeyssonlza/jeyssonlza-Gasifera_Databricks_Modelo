# Fase 2 — Pipeline medallón con calidad de datos (🥈 Silver → 🥇 Gold)

> Prompt a pegar tras completar la fase 1.

---

```text
FASE 2 — PIPELINE DECLARATIVO. Crea un Lakeflow Spark Declarative Pipeline
llamado "Gasifera Pipeline Calidad y Gold" (serverless, catálogo <catalog>,
schema gasifera_silver) cuyo código fuente sean archivos SQL en
transformations/silver y transformations/gold.

SILVER (12 materialized views con CREATE OR REFRESH MATERIALIZED VIEW):
- Una por hecho (consumo, presiones, calidad_gas, interrupciones,
  incidentes_seguridad, mantenimiento, atencion_clientes, conexiones,
  finanzas, compras_suministro, ambiental, metricas_agepar).
- Cada una con EXPECTs de calidad (ON VIOLATION DROP ROW para claves y valores
  imposibles; warn simple para alertas de negocio), inspiradas en:
  claves no nulas, presion_barg > 0, satisfaccion BETWEEN 1 AND 5,
  montos >= 0, dominios de estado válidos, ticket único.
- Deduplicación idempotente con QUALIFY row_number() OVER (PARTITION BY clave
  ORDER BY criterio) = 1 donde aplique (ej: ticket único).

CHEQUEOS DQ PRIVADOS (archivo dq_fk_checks.sql, CREATE OR REFRESH PRIVATE
MATERIALIZED VIEW con REFRESH POLICY INCREMENTAL):
- 6 anti-joins de claves foráneas (consumo→clientes, atencion→clientes,
  conexiones→clientes, presiones→estaciones, calidad→estaciones,
  mantenimiento→empleados) + 1 regla de negocio (cliente 'baja' con consumo
  en el último mes).
- Todos con CONSTRAINT ... ON VIOLATION FAIL UPDATE. Un MV vacío = datos
  válidos; si aparecen filas, el pipeline debe fallar.

GOLD (7 tablas con nombre calificado <catalog>.gasifera_gold.*, también como
MVs del pipeline):
- gold_consumo_mensual: por periodo/region/tipo_cliente: clientes, volumen,
  energia, facturacion, impago.
- gold_clientes_360: por cliente: consumo agregado + atención + riesgo_baja
  (estado='baja' O meses_con_consumo<=3).
- gold_operaciones_mensual: por mes/region: SOLO interrupciones NO programadas
  (criterio regulatorio de SAIDI), incidentes, presiones medias, calidad.
- gold_kpis_agepar_largo: formato largo (mes × 7 indicadores): valor, meta,
  sentido ('mayor_mejor'/'menor_mejor') y cumplimiento (bool). Indicadores SIN
  tildes: 'SAIDI (min/mes)', 'SAIFI (int./cliente)', 'Fugas por 100 km de red',
  'Perdidas %', 'Cobertura %', 'Dias conexion media', '% Ejecucion CAPEX'.
- gold_finanzas_mensual: por mes/tipo_gasto: plan, real, desvio_pct.
- gold_mantenimiento_mensual: por mes/tipo_orden: ordenes, completadas,
  pct_en_plazo, horas, costo.
- gold_suministro_mensual: por mes: contratado vs entregado, cumplimiento,
  precio_medio, penalidades.

Cuando el pipeline esté listo, ejecuta un DRY RUN y luego el update real.

VERIFICACIÓN: (a) el pipeline termina COMPLETED sin errores, (b) las 7 chequeos
privados están VACÍOS, (c) gold_consumo_mensual tiene 1.400 filas y el total de
facturación coincide con la suma de fact_consumo_mensual, (d)
gold_kpis_agepar_largo tiene 7 filas por mes (35×7=245... multiplícalo por las
regiones que incluyas y explícalo).
```

### Criterios de aceptación
- [ ] Pipeline COMPLETED, 12 silver + 7 gold + 7 chequeos creados
- [ ] Chequeos privados vacíos (datos válidos) y expectativas visibles en la pestaña Data quality
- [ ] Conciliación: suma de facturación gold == suma silver == suma bronze

### Errores típicos
* `ON VIOLATION WARN ROW` no existe — la acción warn es NO poner cláusula.
* Olvidar que un MV vacío con FAIL UPDATE es el estado CORRECTO de un chequeo FK.
* Referenciar gold sin nombre calificado — usa `<catalog>.gasifera_gold.*`.
