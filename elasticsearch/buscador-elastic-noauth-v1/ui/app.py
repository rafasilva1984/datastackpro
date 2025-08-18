import os, requests
import streamlit as st
from dotenv import load_dotenv

load_dotenv()
API = "http://search-api:8000"

st.set_page_config(page_title="Buscador Elastic (no-auth)", layout="wide")
st.title("🔎 Buscador Unificado — Elastic 8.x (sem autenticação)")

tabs = st.tabs(["Ingestão Local", "Ingestão Confluence", "Busca"])

# ---------------- Ingestão Local ----------------
with tabs[0]:
    st.subheader("Ingestão de Conteúdo (arquivos locais)")
    st.write("Coloque arquivos em `./data/docs` (PDF, TXT, MD).")
    if st.button("▶️ Rodar ingestão (local)"):
        with st.spinner("Ingerindo conteúdo local..."):
            try:
                r = requests.post(f"{API}/ingest", timeout=1200)
                r.raise_for_status()
                data = r.json()
                st.success(
                    f"Ingestão (local) concluída! {data['total_chunks']} chunks "
                    f"(embeddings: {'ativados' if data.get('used_embeddings') else 'desligados'})"
                )
            except Exception as e:
                st.error(f"Falha na ingestão local: {e}")

# --------------- Ingestão Confluence ---------------
with tabs[1]:
    st.subheader("Ingestão de Conteúdo — Confluence")
    st.caption("Usa variáveis de ambiente: CONFLUENCE_URL, CONFLUENCE_USER, CONFLUENCE_TOKEN, CONFLUENCE_SPACE.")
    if st.button("🏢 Rodar ingestão Confluence"):
        with st.spinner("Buscando páginas no Confluence..."):
            try:
                r = requests.post(f"{API}/ingest_confluence", timeout=1800)
                r.raise_for_status()
                data = r.json()
                if data.get("total_chunks", 0) == 0:
                    st.warning("Nenhum documento ingerido. Verifique as variáveis do Confluence no .env.")
                else:
                    st.success(
                        f"Ingestão (Confluence) concluída! {data['total_chunks']} chunks "
                        f"(embeddings: {'ativados' if data.get('used_embeddings') else 'desligados'})"
                    )
            except Exception as e:
                st.error(f"Falha na ingestão do Confluence: {e}")

# --------------------- Busca ----------------------
with tabs[2]:
    st.subheader("Busca")

    with st.sidebar:
        st.header("Filtros")
        categoria = st.selectbox("Categoria", options=["(todas)", "RH", "Infra", "Suporte", "Compliance", "Mudanças"], index=0)
        tags_sel = st.multiselect("Tags", options=["home-office","beneficios","remoto","vpn","mfa","viagens","reembolso","sla","lgpd","cab","change"], default=[])

    q = st.text_input("Digite sua pergunta", placeholder="Ex.: teto de hospedagem, incidente P1, onboarding, etc.")
    k = st.slider("Resultados", min_value=3, max_value=15, value=5, step=1)

    if st.button("🔍 Buscar") and q.strip():
        with st.spinner("Buscando..."):
            try:
                payload = {
                    "query": q,
                    "k": k,
                    "categoria": None if categoria == "(todas)" else categoria,
                    "tags": tags_sel or None
                }
                r = requests.post(f"{API}/search", json=payload, timeout=60)
                r.raise_for_status()
                results = r.json().get("results", [])
                if not results:
                    st.warning("Nenhum resultado encontrado. Tente refinar sua busca.")
                else:
                    for hit in results:
                        md = hit.get("metadata", {})
                        title = md.get("title") or "(sem título)"
                        source = md.get("source") or "desconhecido"
                        path = md.get("path") or ""
                        cat  = md.get("categoria") or "-"
                        tg   = ", ".join(md.get("tags") or [])
                        st.markdown(f"### {hit['rank']}. {title}")
                        st.caption(f"Fonte: **{source}**  •  {path}  •  Categoria: {cat}  •  Tags: {tg}")
                        st.write(hit["document"], unsafe_allow_html=True)  # highlight quando houver
                        st.divider()
            except Exception as e:
                st.error(f"Falha na busca: {e}")
