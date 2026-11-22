-- Capa silver: calidad del gas validada.
CREATE OR REFRESH MATERIALIZED VIEW silver_calidad_gas (
  CONSTRAINT estacion_presente EXPECT (estacion_id IS NOT NULL AND periodo IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT pci_positivo EXPECT (pci_kwh_m3 > 0) ON VIOLATION DROP ROW,
  CONSTRAINT azufre_no_negativo EXPECT (azufre_total_ppm >= 0),
  CONSTRAINT co2_no_negativo EXPECT (co2_pct >= 0)
)
COMMENT 'Calidad del gas validada: PCI positivo y parametros no negativos'
AS SELECT *
FROM workspace.gasifera.fact_calidad_gas;
