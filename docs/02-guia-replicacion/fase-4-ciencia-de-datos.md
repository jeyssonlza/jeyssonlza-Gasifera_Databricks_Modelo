# Fase 4 — Ciencia de datos con honestidad metodológica (🧪 ML)

> Prompt a pegar tras completar la fase 2 (no requiere la 3).

---

```text
FASE 4 — CIENCIA DE DATOS. Crea el notebook "Gasifera ML Churn y Forecasting"
con MLflow activo y dos problemas en serie.

PROBLEMA A — CHURN (clasificación):
1. Dataset: clientes con features PRE-baja únicamente: tipo_cliente, region,
   antiguedad_meses, tickets de soporte, pct_sla, satisfaccion_media.
   PROHIBIDO usar volumen/facturación posteriores a la baja (filtración:
   son 0 PORQUE se dieron de baja).
2. Split estratificado 80/20 (seed 42), peso de clases (weightCol) por el
   desbalance (~5% bajas).
3. Entrena Regresión Logística y Random Forest; métricas: AUC-ROC, AUC-PR
   (con baseline de prevalencia) y lift del decil superior.
4. REGISTRA las métricas y las importancias en tablas <catalog>.gasifera.
   ml_churn_* y el top-20 de riesgo en ml_clientes_riesgo.
5. REPORTA CON HONESTIDAD: si AUC-PR ≈ baseline, declara explícitamente que
   los datos sintéticos NO contienen señal de churn y que el framework está
   listo para datos reales. NO inventes métricas ni fuerces el resultado.

PROBLEMA B — FORECAST DE DEMANDA (series de tiempo):
1. Serie mensual de demanda total desde gold_consumo_mensual (35 meses).
2. Validación temporal ESTRICTA: train = ene-2024 a jun-2026, test = jul a
   nov-2026. Jamás barajes (shuffle) una serie temporal.
3. Compara: (a) naive estacional (valor del mismo mes del año anterior),
   (b) regresión con lag-12 + términos seno/coseno + tendencia.
4. Métricas: MAPE, MAE y MASE (escala contra el naive). Elige el modelo GANADOR
   por evidencia, no por preferencia.
5. Reentrena el ganador con TODO el historial y genera la proyección a 6 meses
   (dic-2026 a may-2027) TOTAL + por región; guárdala en
   <catalog>.gasifera.ml_forecast_demanda con una columna referencia_12m.
6. Guarda métricas y validación en ml_forecast_metricas y ml_forecast_validacion.

MLOPS: activa el experimento MLflow "gasifera" y loguea el modelo ganador con
mlflow.spark.log_model (los artefactos en un volumen UC). En serverless,
mlflow.spark.log_model exige ruta UC y el input_example no admite Decimal:
convierte a float.

VERIFICACIÓN: (a) tablas ml_* creadas con métricas coherentes entre sí,
(b) la validación temporal muestra train/test sin solapamiento, (c) la
proyección a 6 meses es plausible vs el último año real, (d) el run de MLflow
existe con el modelo registrado.
```

### Criterios de aceptación
- [ ] Churn evaluado sin filtración y con reporte honesto del resultado (señal o no señal, demostrado)
- [ ] Forecast con validación temporal correcta y MASE calculado contra el naive
- [ ] Proyección 6 meses TOTAL + 8 regiones en `ml_forecast_demanda`
- [ ] Run de MLflow con modelo SparkML logueado

### Errores típicos
* Usar variables post-baja en churn → métrica inflada por filtración.
* Validar series temporales con split aleatorio → fuga de futuro.
* `F.vector_to_array` no existe en serverless → usa `toPandas()` y selección por posición.
