import os, requests, textwrap
import streamlit as st
from dotenv import load_dotenv

load_dotenv()
API = "http://search-api:8000"

st.set_page_config(page_title="Buscador Elastic (no-auth)", layout="wide")
st.title("🔎 Buscador Unificado — Elastic 8.x (sem autenticação)")

tabs = st.tabs(["Ingestão", "Busca"])

with tabs[0]:
    st.subheader("Ingestão de Conteúdo (arquivos locais)")
    st.write("Coloque arquivos em `./data/docs` (PDF, TXT, MD).")
    if st.button("▶️ Rodar ingestão agora"):
        with st.spinner("Ingerindo conteúdo..."):
            try:
                r = requests.post(f"{API}/ingest", timeout=1200)
                r.raise_for_status()
                data = r.json()
                st.success(f"Ingestão concluída: {data['total_chunks']} chunks (arquivos locais)")
            except Exception as e:
                st.error(f"Falha na ingestão: {e}")

with tabs[1]:
    st.subheader("Busca")
    q = st.text_input("Digite sua pergunta", placeholder="Ex.: política de home office, guia de VPN, etc.")
    k = st.slider("Resultados", min_value=3, max_value=15, value=5, step=1)
    if st.button("🔍 Buscar") and q.strip():
        with st.spinner("Buscando..."):
            try:
                r = requests.post(f"{API}/search", json={"query": q, "k": k}, timeout=60)
                r.raise_for_status()
                results = r.json().get("results", [])
                if not results:
                    st.warning("Nenhum resultado encontrado.")
                else:
                    for hit in results:
                        md = hit.get("metadata", {})
                        title = md.get("title") or "(sem título)"
                        source = md.get("source") or "desconhecido"
                        path = md.get("path") or ""
                        st.markdown(f"### {hit['rank']}. {title}")
                        st.caption(f"Fonte: **{source}**  •  {path}")
                        st.write(textwrap.shorten(hit["document"], width=600, placeholder=" ..."))
                        st.divider()
            except Exception as e:
                st.error(f"Falha na busca: {e}")
