-- Capa silver: consumo mensual validado.
-- Reglas DQ aplicadas: DQ02 (clave unica), DQ13 (volumen >= 0), DQ14 (energia ≈ volumen*10.7 ±15%),
-- DQ15 (monto ≈ volumen*tarifa ±15%), dominio de tipo_cliente.
CREATE OR REFRESH MATERIALIZED VIEW silver_consumo_mensual (
  CONSTRAINT claves_presentes EXPECT (cliente_id IS NOT NULL AND periodo IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT volumen_no_negativo EXPECT (volumen_m3 >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT energia_coherente EXPECT (ABS(energia_kwh - volumen_m3 * 10.7) <= 0.15 * volumen_m3 * 10.7),
  CONSTRAINT monto_coherente EXPECT (ABS(monto_facturado_usd - volumen_m3 * tarifa_usd_m3) <= 0.15 * volumen_m3 * tarifa_usd_m3),
  CONSTRAINT dominio_tipo_cliente EXPECT (tipo_cliente IN ('residencial', 'comercial', 'industrial', 'gnv', 'termoelectrico'))
)
COMMENT 'Consumo mensual validado: clave (cliente_id, periodo) unica, volumenes no negativos y coherencia energia/monto'
AS SELECT *
FROM workspace.gasifera.fact_consumo_mensual
QUALIFY row_number() OVER (PARTITION BY cliente_id, periodo ORDER BY monto_facturado_usd DESC) = 1;
