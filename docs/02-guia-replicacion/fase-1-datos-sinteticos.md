# Fase 1 — Datos sintéticos deterministas (🥉 Bronze)

> Prompt a pegar cuando el prompt maestro (fase 0) ya fue confirmado.

---

```text
FASE 1 — DATOS SINTÉTICOS. Crea un notebook llamado "Proyecto Gasifera Datos
Sinteticos" y ejecútalo. Debe generar, en el schema <catalog>.gasifera, 17
tablas deterministas (SEED=42) cubriendo ene-2024 a nov-2026 (35 meses):

DIMENSIONES:
- dim_regiones (8): id, nombre, tipo (ciudad capital / intermedia / rural),
  longitud_red_km, clientes potenciales.
- dim_estaciones (40): id EST000+, región, capacidad, fecha de puesta en marcha.
- dim_red_segmentos (2.500): id SEG0000+, estación, longitud, material, año.
- dim_clientes (18.000): id CLI000+, tipo (residencial/comercial/industrial),
  razón social, contacto, documento (formato DOC-#########), región,
  fecha_alta (1999-2019, sesgada), estado (activo/baja), tarifa.
- dim_empleados (1.200): id EMP00000+, cargo, región, fecha_ingreso.

HECHOS (todas con clave de mes 'YYYY-MM' cuando aplique):
- fact_consumo_mensual: una fila por cliente-mes ACTIVO (≈630.000); volumen m3
  con estacionalidad invernal (jun-ago 60-90% sobre verano) según tipo de
  cliente; energía = volumen * PCI (≈10,7 kWh/m3); monto = energía * tarifa;
  impago binario (~5%, correlado con clientes comerciales grandes).
- fact_presiones (200.000): mediciones por estación-mes; presión_barg > 0;
  fuera_de_rango es un dato legítimo de operación (~3%), no un error.
- fact_calidad_gas (1.400): por estación-mes: PCI, H2S, CO2, humedad.
- fact_interrupciones (4.200): programadas vs NO programadas (afectan SAIDI),
  clientes_afectados, duración_min, segmento.
- fact_incidentes_seguridad (2.600): tipo, gravedad, estación, segmento.
- fact_mantenimiento (30.000): órdenes por empleado/estación, tipo
  (correctivo/preventivo/urgencia), horas, costo, completada, en_plazo.
- fact_atencion_clientes (60.000): tickets con satisfaccion 1-5, resolucion_h.
- fact_conexiones (15.000): altas nuevas con dias_desde_solicitud.
- fact_finanzas (3.360): por mes y tipo_gasto (capex/opex): planificado y real
  con desvíos plausibles (CAPEX global ≈ 100%).
- fact_compras_suministro (210): por mes y proveedor: contratado vs entregado,
  precio, penalidades cuando entregado < contratado.
- fact_ambiental (280): emisiones CO2, energía, agua por mes.

REQUISITOS TÉCNICOS:
- Un solo notebook, ejecuciones idempotentes (DROP TABLE IF EXISTS + CREATE).
- Todo con escribir en Delta gestionado por Unity Catalog.
- Al final imprime un resumen de conteos por tabla.

VERIFICACIÓN (muéstrame el resultado): (a) conteo de las 17 tablas, (b) consumo
total por año con clara estacionalidad invernal, (c) 5 filas de
fact_consumo_mensual y dim_clientes, (d) la misma celda reejecutada produce
exactamente los mismos valores.
```

### Criterios de aceptación
- [ ] 17 tablas existen en `<catalog>.gasifera` con los conteos esperados (~1,1 M filas en total)
- [ ] Estacionalidad visible: consumo jun-ago > ene-feb en cada año
- [ ] Determinismo: reejecutar produce valores idénticos

### Errores típicos
* Perder el determinismo usando `rand()` de Spark sin seed → siempre `random.Random(42)` de Python materializado a columnas.
* Usar tildes en nombres de columnas → rompe SQL aguas abajo.
