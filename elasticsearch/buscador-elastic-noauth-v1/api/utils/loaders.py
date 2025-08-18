import os, re, pathlib
from typing import List, Dict
from bs4 import BeautifulSoup
from markdown import markdown
from pypdf import PdfReader

SUPPORTED_EXT = {'.pdf', '.txt', '.md'}

def clean_text(text: str) -> str:
    text = re.sub(r'\s+', ' ', text or '').strip()
    return text

def chunk_text(text: str, chunk_size: int = 800, overlap: int = 120) -> List[str]:
    words = text.split()
    chunks, start = [], 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunk = ' '.join(words[start:end])
        chunks.append(chunk)
        if end == len(words): break
        start = max(end - overlap, 0)
    return chunks

def parse_pdf(path: str) -> str:
    try:
        reader = PdfReader(path)
        texts = []
        for page in reader.pages:
            txt = page.extract_text() or ''
            texts.append(txt)
        return clean_text(' '.join(texts))
    except Exception:
        return ""

def parse_md(path: str) -> str:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            md = f.read()
        html = markdown(md)
        soup = BeautifulSoup(html, 'html.parser')
        return clean_text(soup.get_text(' '))
    except Exception:
        return ""

def parse_txt(path: str) -> str:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return clean_text(f.read())
    except Exception:
        return ""

def load_local_docs(root_dir: str) -> List[Dict]:
    items = []
    for p in pathlib.Path(root_dir).rglob('*'):
        if not p.is_file(): continue
        ext = p.suffix.lower()
        if ext not in SUPPORTED_EXT: continue
        text = ""
        if ext == '.pdf':
            text = parse_pdf(str(p))
        elif ext == '.md':
            text = parse_md(str(p))
        elif ext == '.txt':
            text = parse_txt(str(p))
        if not text: continue
        chunks = chunk_text(text)
        for i, ch in enumerate(chunks):
            items.append({
                "id": f"local::{p.name}::{i}",
                "source": "local",
                "path": str(p),
                "title": p.stem,
                "text": ch
            })
    return items
