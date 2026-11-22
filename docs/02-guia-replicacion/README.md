# Guía de replicación — reconstruye Gasífera en cualquier cuenta de Databricks

Esta carpeta convierte el proyecto completo en una **secuencia de prompts guiados**. Están pensados para pegarse en el asistente de Databricks (Genie Code / Databricks Assistant) de cualquier cuenta — incluida **Free Edition** — y obtener el proyecto completo fase a fase, con verificación al final de cada una.

## Cómo usarlo

1. Lee `fase-0-prompt-maestro.md` — es el **prompt real principal**: pégalo primero y le da al asistente el contexto completo del proyecto (negocio, convenciones, reglas de calidad).
2. Ejecuta las fases **en orden**. Cada archivo `fase-N-*.md` es un prompt listo para copiar/pegar, con sus **criterios de aceptación** al final: no pases a la siguiente fase hasta que la actual los cumpla.
3. Si algo falla, pega el error al asistente tal cual — cada fase incluye los errores típicos y su arreglo.

## Las fases

| Archivo | Fase | Qué construye |
| --- | --- | --- |
| `fase-0-prompt-maestro.md` | Contexto | El "ADN" del proyecto: negocio, convenciones y reglas que todas las demás fases heredan |
| `fase-1-datos-sinteticos.md` | 🥉 Bronze | Notebook PySpark determinista: 17 tablas, 35 meses, 8 regiones |
| `fase-2-pipeline-silver-gold.md` | 🥈 Silver | Lakeflow SDP: 12 MVs con expectativas, 7 chequeos DQ privados, 7 gold |
| `fase-3-ingesta-avanzada.md` | ⚙️ Professional | Auto Loader + Auto CDC SCD Type 2 con backfill + liquid clustering |
| `fase-4-ciencia-de-datos.md` | 🧪 ML | Churn honesto + forecast con validación temporal + MLflow |
| `fase-5-dashboards-genie.md` | 📊 BI | 4 dashboards AI/BI + agente Genie curado + alerta programada |
| `fase-6-automatizacion-gobernanza.md` | 🚀 Ops | Job mensual con retries + ABAC + lineage + bundle Git |

## Regla de oro

> **Verifica antes de avanzar.** Cada fase termina con una consulta SQL o una comprobación concreta. Si el resultado no coincide con lo esperado, el asistente debe corregirlo antes de continuar — así se evita acumular errores silenciosos.
