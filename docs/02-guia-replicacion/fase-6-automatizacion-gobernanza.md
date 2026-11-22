# Fase 6 — Automatización, gobernanza y control de versiones (🚀 Ops)

> Prompt final. Requiere todas las fases anteriores.

---

```text
FASE 6 — OPERACIÓN Y GOBERNANZA.

A) JOB PROGRAMADO CON REINTENTOS:
- Crea un job "Gasifera Regenerar Forecast" que ejecute el notebook de ML
  (solo la parte de forecast), programado el día 2 de cada mes a las 05:00
  (America/Bogota), con: max_retries = 3, intervalo entre reintentos de 5
  minutos y reintento también por TIMEOUT.
- El diseño importa: el forecast se regenera el día 2 para que la alerta de
  desviación (día 3) compare SIEMPRE contra la proyección más fresca.
- Ejecuta el job una vez y verifica el estado SUCCEEDED.

B) GOBERNANZA — UNITY CATALOG:
1. Lineage: verifica y documenta la trazabilidad gold_consumo_mensual →
   silver_consumo_mensual → fact_consumo_mensual (pestaña Lineage de UC).
2. ABAC (Advanced Governance, si tu workspace lo tiene):
   - Crea el governed tag 'class.es_dni' (namespace class. para clasificación
     de sensibilidad).
   - Asigna el tag a dim_clientes.documento.
   - Crea la función de máscara <catalog>.gasifera.mascara_pii(col STRING)
     → devuelve 'XXXX-XXXXX-' || right(col, 3).
   - Crea una política de máscara a NIVEL SCHEMA con MATCH COLUMNS: la regla
     es has_tag('es_dni') — no usa comparadores ni nombres de columna.
   - VERIFICA: un usuario no propietario ve 'XXXX-XXXXX-123' y el propietario
     ve el valor real.
3. Documenta quién puede ver qué (propietario vs otros) y qué tablas quedan
   cubiertas por la máscara.

C) CONTROL DE VERSIONES — DECLARATIVE AUTOMATION BUNDLE:
1. Conecta el workspace a GitHub (Settings → Linked accounts, o token de
   acceso personal con scope repo).
2. Crea/clona el repo y usa el asistente de migración para mover el pipeline
   a un bundle dentro del repo (target 'dev').
3. IMPORTANTE: si la migración falla porque hay un directorio ilegible en la
   carpeta fuente (p.ej. un residuo de mlflow), muestra su contenido; si está
   vacío, pide confirmación para eliminarlo y reintenta.
4. NO elimines la carpeta fuente original si el job programado todavía apunta
   a notebooks de ella (repunta el job primero).
5. Commit y push de TODO el proyecto (código, dashboards, docs) al repo.

D) DOCUMENTACIÓN FINAL:
- Un README de portfolio con las tres áreas (Ingeniería / Análisis /
  Ciencia de Datos) y evidencia medible de cada una.
- Un documento de ingeniería inversa con arquitectura, modelo de datos,
  decisiones y errores resueltos.

VERIFICACIÓN: (a) job SUCCEEDED con política de reintentos visible en su
configuración, (b) máscara ABAC demostrada (valor enmascarado vs real),
(c) lineage completo en UC, (d) repo GitHub con el bundle y los documentos,
(e) dry run del pipeline desde el bundle COMPLETED.
```

### Criterios de aceptación
- [ ] Job mensual SUCCEEDED con retries configurados
- [ ] ABAC: tag + máscara a nivel schema demostrada con dos vistas (propietario vs no)
- [ ] Lineage end-to-end visible en UC
- [ ] Bundle en Git: `databricks.yml` + pipeline YAML + SQL versionado, y dry run OK
- [ ] README + ingeniería inversa publicados en el repo

### Errores típicos
* Enmascarar antes de verificar → demuestra la máscara con un usuario/rol distinto.
* Mover a papelera la carpeta fuente con el job apuntando a ella → rompe el job del mes siguiente.
* Tokens de Git sin scope `repo` → la clonación falla con UNAUTHENTICATED.
