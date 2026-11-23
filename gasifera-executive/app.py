"""
Gasifera Executive — Panel ejecutivo del proyecto Gasífera del Valle S.A.

App de portfolio sobre Databricks Apps (Streamlit). Lee las tablas gold y ML
 del proyecto (Unity Catalog) vía la Statement Execution API con la identidad
de la app (OAuth automático del service principal).

Proyecto: distribuidora de gas natural regulada (AGEPAR), datos sintéticos
deterministas, pipeline medallón con Lakeflow Spark Declarative Pipelines.
"""

import json
import os

import pandas as pd
import streamlit as st
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import Disposition, Format

WAREHOUSE_ID = os.environ.get("DATABRICKS_WAREHOUSE_ID", "f187d9ab39b6bd9f")

GOLD = "workspace.gasifera_gold"
BASE = "workspace.gasifera"

st.set_page_config(page_title="Gasifera Executive", page_icon="🔥", layout="wide")


@st.cache_resource(show_spinner=False)
def get_client():
    return WorkspaceClient()


@st.cache_data(ttl=600, show_spinner=False)
def query(sql_text: str) -> pd.DataFrame:
    w = get_client()
    resp = w.statement_execution.execute_statement(
        warehouse_id=WAREHOUSE_ID,
        statement=sql_text,
        wait_timeout="50s",
        format=Format.JSON_ARRAY,
        disposition=Disposition.INLINE,
    )
    if resp.status.error:
        raise RuntimeError(resp.status.error.message)
    cols = [c.name for c in resp.manifest.schema.columns]
    arr = resp.result.data_array if resp.result else None
    rows = [list(r) for r in arr] if arr else []
    df = pd.DataFrame(rows, columns=cols)
    # Los valores llegan como strings; convierte a numérico lo que se pueda
    # (fechas e IDs quedan como texto porque to_numeric no los convierte).
    for c in df.columns:
        num = pd.to_numeric(df[c], errors="coerce")
        if len(df) > 0 and num.notna().all():
            df[c] = num
    return df


# ---------------------------------------------------------------- datos
@st.cache_data(ttl=600, show_spinner=False)
def kpi_global() -> float:
    q = f"""SELECT AVG(CASE WHEN cumple_meta THEN 1.0 ELSE 0.0 END) * 100 AS pct
            FROM {GOLD}.gold_kpis_agepar_largo"""
    return float(query(q)["pct"].iloc[0])


@st.cache_data(ttl=600, show_spinner=False)
def capex_ejecucion() -> float:
    q = f"""SELECT SUM(real_usd) * 100.0 / SUM(plan_usd) AS pct
            FROM {GOLD}.gold_finanzas_mensual WHERE tipo_gasto = 'capex'"""
    return float(query(q)["pct"].iloc[0])


@st.cache_data(ttl=600, show_spinner=False)
def demanda_ultimo_mes() -> float:
    q = f"""SELECT SUM(volumen_m3) / 1e6 AS mm3 FROM {GOLD}.gold_consumo_mensual
            WHERE periodo = (SELECT MAX(periodo) FROM {GOLD}.gold_consumo_mensual)"""
    return float(query(q)["mm3"].iloc[0])


@st.cache_data(ttl=600, show_spinner=False)
def proyeccion_6m() -> float:
    q = f"""SELECT SUM(prediccion_m3) / 1e6 AS mm3 FROM {BASE}.ml_forecast_demanda
            WHERE region = 'TOTAL'"""
    return float(query(q)["mm3"].iloc[0])


@st.cache_data(ttl=600, show_spinner=False)
def serie_demanda() -> pd.DataFrame:
    real = query(f"""SELECT CAST(periodo AS STRING) AS periodo,
                            SUM(volumen_m3) / 1e6 AS volumen
                     FROM {GOLD}.gold_consumo_mensual GROUP BY 1 ORDER BY 1""")
    real["tipo"] = "Real"
    fc = query(f"""SELECT CAST(periodo AS STRING) AS periodo,
                          SUM(prediccion_m3) / 1e6 AS volumen
                   FROM {BASE}.ml_forecast_demanda WHERE region = 'TOTAL'
                   GROUP BY 1 ORDER BY 1""")
    fc["tipo"] = "Proyeccion"
    return pd.concat([real, fc], ignore_index=True)


@st.cache_data(ttl=600, show_spinner=False)
def kpis_evolucion() -> pd.DataFrame:
    return query(f"""SELECT CAST(periodo AS STRING) AS periodo,
                            AVG(CASE WHEN cumple_meta THEN 1.0 ELSE 0.0 END) * 100 AS cumplimiento
                     FROM {GOLD}.gold_kpis_agepar_largo GROUP BY 1 ORDER BY 1""")


@st.cache_data(ttl=600, show_spinner=False)
def capex_plan_real() -> pd.DataFrame:
    return query(f"""SELECT CAST(periodo AS STRING) AS periodo,
                            SUM(CASE WHEN tipo_gasto = 'capex' THEN plan_usd END) / 1e6 AS plan_musd,
                            SUM(CASE WHEN tipo_gasto = 'capex' THEN real_usd END) / 1e6 AS real_musd
                     FROM {GOLD}.gold_finanzas_mensual GROUP BY 1 ORDER BY 1""")


@st.cache_data(ttl=600, show_spinner=False)
def facturacion_region() -> pd.DataFrame:
    return query(f"""SELECT region, SUM(facturacion_usd) / 1e6 AS facturacion_musd
                     FROM {GOLD}.gold_consumo_mensual GROUP BY 1 ORDER BY 2 DESC""")


@st.cache_data(ttl=600, show_spinner=False)
def clientes_riesgo() -> pd.DataFrame:
    return query(f"""SELECT cliente_id, tipo_cliente, region,
                            ROUND(prob_baja * 100, 1) AS prob_baja_pct
                     FROM {BASE}.ml_clientes_riesgo ORDER BY prob_baja DESC LIMIT 20""")


# ---------------------------------------------------------------- UI
st.title("🔥 Gasifera Executive")
st.caption(
    "Panel ejecutivo de **Gasífera del Valle S.A.** — distribuidora de gas natural "
    "regulada por la AGEPAR. Datos sintéticos deterministas servidos en vivo desde "
    "las tablas gold del lakehouse (Unity Catalog + Lakeflow Spark Declarative Pipelines)."
)

try:
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Cumplimiento de metas AGEPAR", f"{kpi_global():.1f}%")
    c2.metric("Ejecución CAPEX (acumulada)", f"{capex_ejecucion():.1f}%")
    c3.metric("Demanda mensual (último mes)", f"{demanda_ultimo_mes():,.1f} Mm³")
    c4.metric("Proyección demanda 6 meses", f"{proyeccion_6m():,.1f} Mm³")

    left, right = st.columns(2)

    with left:
        st.subheader("Demanda real y proyección (Mm³/mes)")
        df = serie_demanda()
        st.line_chart(df.pivot(index="periodo", columns="tipo", values="volumen"))
        st.caption("Naive estacional validado temporalmente · MAPE 2,86 % · job mensual de regeneración")

        st.subheader("CAPEX: plan vs real (M USD/mes)")
        dfc = capex_plan_real()
        st.bar_chart(dfc.set_index("periodo"))

    with right:
        st.subheader("Cumplimiento de KPIs por mes (%)")
        st.line_chart(kpis_evolucion().set_index("periodo"))

        st.subheader("Facturación acumulada por región (M USD)")
        st.bar_chart(facturacion_region().set_index("region"))

    st.subheader("Top-20 clientes con mayor probabilidad de baja")
    st.caption("Demostración del framework de churn (los datos sintéticos no contienen señal; ver métricas en el dashboard ML)")
    st.dataframe(clientes_riesgo(), use_container_width=True, hide_index=True)

    st.divider()
    st.caption(
        " Construido con Databricks Free Edition · Unity Catalog · Lakeflow SDP · "
        "Auto Loader · Auto CDC SCD2 · MLflow · Databricks Apps. "
        "Código y documentación: github.com/jeyssonlza/jeyssonlza-Gasifera_Databricks_Modelo"
    )

except Exception as exc:  # pragma: no cover
    st.error(f"Error consultando el lakehouse: {exc}")
    st.caption("Verifica que el SQL warehouse esté accesible para el service principal de la app.")
