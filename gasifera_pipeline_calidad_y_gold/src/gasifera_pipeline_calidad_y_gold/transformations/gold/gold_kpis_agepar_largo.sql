-- Capa gold: KPIs regulatorios AGEPAR en formato largo (indicador / valor / meta / sentido / cumple_meta).
-- Stack de 7 KPIs derivado de las metricas mensuales por region.
CREATE OR REFRESH MATERIALIZED VIEW workspace.gasifera_gold.gold_kpis_agepar_largo
COMMENT 'KPIs AGEPAR en formato largo: 7 indicadores con valor, meta, sentido y cumplimiento'
AS
SELECT periodo, region, 'SAIDI (min/mes)' AS indicador, saidi_min AS valor, saidi_meta_min AS meta,
       'menor_es_mejor' AS sentido, saidi_min <= saidi_meta_min AS cumple_meta
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, 'SAIFI (int./cliente)', saifi, saifi_meta, 'menor_es_mejor', saifi <= saifi_meta
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, 'Fugas por 100 km de red', fugas_por_100km, fugas_meta_100km, 'menor_es_mejor', fugas_por_100km <= fugas_meta_100km
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, 'Perdidas %', perdidas_pct, perdidas_meta_pct, 'menor_es_mejor', perdidas_pct <= perdidas_meta_pct
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, 'Cobertura %', cobertura_pct, cobertura_meta_pct, 'mayor_es_mejor', cobertura_pct >= cobertura_meta_pct
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, 'Dias conexion media', dias_conexion_media, dias_conexion_meta, 'menor_es_mejor', dias_conexion_media <= dias_conexion_meta
FROM silver_metricas_agepar
UNION ALL
SELECT periodo, region, '% Ejecucion CAPEX', pct_ejecucion_capex, pct_capex_meta, 'mayor_es_mejor', pct_ejecucion_capex >= pct_capex_meta
FROM silver_metricas_agepar;
