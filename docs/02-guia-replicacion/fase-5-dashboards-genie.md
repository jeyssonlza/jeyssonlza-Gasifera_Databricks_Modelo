# Fase 5 — Dashboards, agente conversacional y alerta (📊 BI)

> Prompt a pegar tras completar las fases 2 y 4 (usa gold y el forecast).

---

```text
FASE 5 — BI Y ANALÍTICA.

A) DASHBOARDS AI/BI (4, todos PUBLICADOS con al menos un visual por página):
1. "Gasifera KPIs AGEPAR": cumplimiento global de KPIs (counter), evolución
   mensual por indicador, ranking de regiones, detalle de incumplimientos,
   SAIDI nacional en línea.
2. "Gasifera Finanzas": ejecución CAPEX (counter con %), plan vs real por mes,
   facturación por región, tasa de impago.
3. "Gasifera Demanda y Forecast": demanda real mensual + proyección a 6 meses
   (línea, uniendo serie real y forecast), desviación del último mes.
4. "Gasifera ML": métricas de modelos churn, importancias, top de riesgo y
   validación del forecast (real vs predicho en test).
Usa las tablas gold y ml_*; añade filtros de fecha y región cuando aporte.

B) AGENTE GENIE (analítica en lenguaje natural):
1. Crea un Genie Space con las tablas gold y las de negocio relevantes.
2. Escribe instrucciones del espacio con: contexto de negocio (AGEPAR, KPIs,
   criterio de interrupciones NO programadas), glosario de términos,
   convenciones (periodo 'YYYY-MM', moneda USD, regiones), y formato de
   respuesta SIEMPRE con tabla + gráfico + un párrafo ejecutivo.
3. Ejecuta un BENCHMARK de 7 preguntas reales de negocio, por ejemplo:
   ¿Cómo evolucionó el cumplimiento de KPIs en los últimos 12 meses?
   ¿Qué regiones incumplen SAIDI y por cuánto? ¿Top 5 clientes por facturación
   con riesgo de baja? ¿Tasa de impago por tipo de cliente? ¿Comparativo de
   ejecución CAPEX 2025 vs 2026? ¿Evolución de reclamos por 1.000 clientes?
   ¿Proyección de demanda para los próximos 6 meses?
4. Verifica CADA respuesta contra los datos (usa SQL directo como oráculo) y
   afina las instrucciones hasta 7/7 correctas. Documenta qué corrección hizo
   falta (p.ej. escala de porcentajes).

C) ALERTA SQL PROGRAMADA:
- "Gasifera Desviacion de Demanda Mensual": desviación % del último mes
  completo vs el MISMO mes del año anterior; alerta si el valor absoluto
  supera 10. Cron: mensual, día 3 (después de la regeneración del forecast).
- La consulta debe devolver UNA fila y UNA columna numérica.

VERIFICACIÓN: (a) 4 dashboards publicados con datos visibles en cada visual,
(b) 7/7 del benchmark Genie con verificación cruzada documentada, (c) la
alerta evaluada manualmente al menos una vez (estado OK o TRIGGERED con
justificación).
```

### Criterios de aceptación
- [ ] 4 dashboards publicados y renderizando datos reales
- [ ] Benchmark Genie 7/7 con verificación cruzada contra SQL directo
- [ ] Alerta programada y evaluada con resultado justificado

### Errores típicos
* Visualizaciones con series por mes: agrupa por `periodo` completo (string 'YYYY-MM' ordena bien).
* El Genie responde con % sin escala → corrige con instrucción explícita ("los porcentajes se almacenan 0-100").
