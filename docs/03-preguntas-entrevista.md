# Preguntas de entrevista sobre este proyecto — y cómo responderlas

Quince preguntas técnicas que es probable que te hagan al presentar Gasífera, con respuestas apoyadas en los **números reales** del proyecto. La regla: responder con el concepto + cómo se resolvió aquí + qué aprenderías a mejorar.

## Ingeniería de datos

**1. ¿Por qué Lakehouse medallón y no un solo schema?**
Bronze (datos tal cual llegan, con sus "suciedades" legítimas), silver (limpieza documentada como código: expectativas DQ + deduplicación), gold (modelado de consumo con lógica regulatoria). En Gasífera esto es verificable: las 12 MVs silver tienen expectativas, y los 7 chequeos privados con `FAIL UPDATE` hacen que el pipeline falle solo si los datos se corrompen.

**2. ¿Cómo funciona Auto Loader y qué lo diferencia de una lectura batch?**
Procesa cada archivo nuevo del volumen **exactamente una vez** usando checkpoints (file notification / listing incremental). Aquí lo demostramos con 14 archivos JSONL → 560 filas en `silver_telemetria`; reejecutar el pipeline no duplica nada.

**3. Explica tu SCD Type 2 con Auto CDC.** (La pregunta estrella)
Tres piezas: (a) `SEQUENCE BY fecha_cambio` ordena el historial por fecha de **negocio**, no de ingesta; (b) el feed de cambios solo trae eventos, así que el estado inicial entra como eventos vía un append flow `INSERT INTO ... ONCE` desde `dim_clientes` con `fecha_cambio = fecha_alta` — sin eso, cada cliente tendría una sola versión; (c) `IGNORE NULL UPDATES` porque los UPDATE solo traen el campo que cambió, y `APPLY AS DELETE` para las bajas. Resultado: 18.075 versiones, exactamente una vigente por cliente, 50 historias cerradas verificadas.

**4. ¿Qué pasa si un flujo CDC pierde su checkpoint?**
Lo vivimos: si cambias la fuente de lectura, el checkpoint queda inválido (`DIFFERENT_DELTA_TABLE_READ_BY_STREAMING_SOURCE`). La solución es **resetear el checkpoint del flujo** (requiere confirmación porque relee desde el inicio) — no borrar la tabla destino, que conserva el historial correcto.

**5. ¿Cómo implementaste la calidad de datos?**
Tres niveles: expectativas inline en cada MV (DROP para imposibles como presión negativa, WARN para anomalías de negocio), 7 chequeos privados (anti-joins de FKs + regla de negocio "baja con consumo") con `FAIL UPDATE`, y conciliación numérica entre capas (facturación bronze = silver = gold).

**6. ¿Qué es liquid clustering y por qué aquí?**
`CLUSTER BY (fecha, region)` en la streaming table: las consultas filtran por rango de fecha y región, y liquid clustering reorganiza los archivos sin necesidad de particionado rígido ni ZORDER. Verificado con `SHOW TBLPROPERTIES`; `OPTIMIZE` ejecutado con métricas.

**7. ¿Cómo garantizas reproducibilidad?**
Datos sintéticos con semilla fija (SEED=42) → misma data en cualquier cuenta; SQL idempotente (`CREATE OR REFRESH`) → el mismo código reconstruye el estado completo; y todo versionado en un Declarative Automation Bundle en Git → infraestructura como código.

## Análisis de datos

**8. ¿Cómo construiste los KPIs regulatorios?**
Se **calculan desde los hechos**, nunca se inventan: SAIDI/SAIFI solo con interrupciones NO programadas (criterio AGEPAR), fugas por 100 km normalizadas por longitud de red, reclamos por 1.000 clientes activos, CAPEX como % de ejecución. El formato largo (`gold_kpis_agepar_largo`: valor, meta, sentido, cumplimiento) permite un solo dashboard genérico para 7 KPIs.

**9. ¿Cómo verificaste el agente Genie?**
Benchmark de 7 preguntas de negocio, cada una contrastada contra SQL directo como oráculo → 7/7. Hubo una corrección documentada: el Genie confundía la escala de porcentajes; se resolvió con instrucciones explícitas del espacio, no con hacks.

**10. ¿Por qué una alerta de desviación de demanda y no de otra cosa?**
Porque es la señal accionable: desviación >10 % del último mes vs el mismo mes del año anterior. Y el diseño es causal: el job regenera el forecast el **día 2** y la alerta corre el **día 3**, para comparar siempre contra la proyección más fresca.

## Ciencia de datos

**11. Tu churn no tiene señal — ¿no es un fracaso?**
Es el mejor resultado posible si los datos no lo contienen. AUC-PR 0,053 vs baseline 0,055: los clientes sintéticos se dan de baja sin comportamiento previo. El mérito metodológico es triple: features sin filtración (excluyo volumen/facturación post-baja, que son 0 PORQUE se fueron), split estratificado con pesos de clase, y reporte honesto con framework listo para datos reales. Reportar métricas infladas habría sido el fracaso real.

**12. ¿Por qué ganó el naive en el forecast y qué harías distinto?**
Naive estacional: MAPE 2,86 %, MASE 1,20 (el MASE mide exactamente eso: el naive es la escala). Con 35 meses de serie estable, un modelo con lag-12 + Fourier + tendencia no puede superar al naive sin más señal. Con más historia o datos por segmento, probaría ETS/ARIMA y features exógenas (precio, temperatura). La decisión se tomó por evidencia de validación temporal estricta (train 30 meses, test 5 meses futuros, sin shuffle).

**13. ¿Cómo gestionas el ciclo de vida del modelo?**
MLflow trackeando experimentos, modelo SparkML logueado con artefactos en un volumen de Unity Catalog, y reentrenamiento automático mensual vía job con `max_retries=3` y reintento por timeout.

## Gobernanza y plataforma

**14. ¿Cómo funciona tu máscara PII?**
Governed tag `class.es_dni` asignado a `dim_clientes.documento` + función `mascara_pii` + política de máscara **a nivel schema** con `MATCH COLUMNS` usando `has_tag('es_dni')` — cualquier columna futura con ese tag queda cubierta automáticamente. Verificado: el propietario ve el valor real, el resto ve `XXXX-XXXXX-123`.

**15. ¿Qué te dio mover todo a un bundle + GitHub?**
Fuente de verdad versionada, revisión por PR, y CI/CD: un workflow de GitHub Actions valida y despliega el bundle con `databricks bundle deploy -t dev` en cada push. El pipeline deja de ser un objeto del workspace y pasa a ser código.

---

*Consejo final: cuando una respuesta no esté en este documento, no improvises números — di "no lo medí, pero así lo mediría".*
