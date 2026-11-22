# Fase 0 — Prompt maestro (el "ADN" del proyecto)

> Este es el **prompt real principal**. Pégalo tal cual en el asistente de Databricks ANTES de cualquier otra fase. Todas las demás fases heredan este contexto.

---

```text
Vas a ayudarme a construir un proyecto completo de datos de nivel profesional en
Databricks. Léelo entero antes de actuar, y respétalo en TODAS las fases.

## CONTEXTO DE NEGOCIO
Gasífera del Valle S.A.: distribuidora de gas natural regulada por la AGEPAR
(agencia regulatoria ficticia). 8 regiones, 40 estaciones de regulación y
medición, 18.000 clientes. La AGEPAR exige reportar: SAIDI, SAIFI, fugas por
100 km de red, reclamos por 1.000 clientes, PCI del gas y % de ejecución CAPEX.
La dirección necesita: cumplimiento regulatorio, control financiero
(CAPEX/OPEX), anticipar la demanda y detectar clientes en riesgo de baja.

## CONVENCIONES OBLIGATORIAS
1. Catálogo de trabajo: el catálogo por defecto del workspace. Los schemas son:
   <catalog>.gasifera (datos base), <catalog>.gasifera_silver (pipeline) y
   <catalog>.gasifera_gold (consumo). Sustituye <catalog> por el real.
2. Datos SINTÉTICOS y DETERMINISTAS: semilla 42 con random.Random y helpers
   elegir(secuencia) y aleatorios(secuencia, min, max). Nunca uses aleatoriedad
   sin semilla: el proyecto debe reproducir números idénticos en cada cuenta.
3. Período de datos: enero 2024 a noviembre 2026 (35 meses completos).
4. IDs con base 0 y ancho fijo: CLI000000+, EST000+, SEG0000+, EMP00000+.
5. Moneda USD. Periodos de consumo en formato 'YYYY-MM' (string).
6. Español para nombres de columnas SIN tildes (ej: 'region', 'presion_barg',
   'tipo_gasto' con valores 'capex'/'opex' en minúscula).
7. Los KPIs AGEPAR se CALCULAN desde los hechos, nunca se inventan:
   - SAIDI/SAIFI: SOLO interrupciones NO programadas.
   - fugas_100km: fugas de gas / (longitud_red_km / 100).
   - reclamos_1000: reclamos / (clientes_activos / 1000).
   - pct_capex: capex_real / capex_planificado * 100.
8. Estacionalidad realista: consumo de invierno (jun-ago en hemisferio sur)
   60-90% superior al verano; ciudades capitales concentran más clientes.

## FILOSOFÍA DE CALIDAD (no negociable)
- Nada se da por bueno: cada entrega se VERIFICA con una consulta concreta antes
  de avanzar. Muéstrame siempre el resultado de la verificación.
- Si un resultado es inesperado, investiga la causa antes de corregir.
- Reporta los malos resultados con honestidad (ej: si un modelo no tiene señal,
  dilo y demuéstralo; nunca infles métricas con filtración de datos).
- El código SQL del pipeline debe ser idempotente (CREATE OR REFRESH).

## HOJA DE RUTA (te la pediré fase por fase)
Fase 1: datos sintéticos (17 tablas). Fase 2: pipeline medallón con DQ.
Fase 3: ingesta incremental (Auto Loader + Auto CDC SCD2) y optimización.
Fase 4: ciencia de datos (churn + forecast + MLflow). Fase 5: dashboards,
agente conversacional y alerta. Fase 6: job programado, gobernanza (ABAC,
lineage) y control de versiones con Git.

Confirma que entendiste el contexto y espera mi instrucción de fase.
```

---

**Por qué funciona este prompt:** fija el negocio (para que el asistente tome decisiones coherentes), las convenciones (para que los nombres y formatos coincidan entre fases), la filosofía de verificación (para que no avances sobre datos dudosos) y la hoja de ruta (para que sepa qué viene y no se adelante).
