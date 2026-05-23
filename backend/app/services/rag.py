import re
from dataclasses import dataclass
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[2]
KNOWLEDGE_BASE_DIR = BACKEND_DIR / "knowledge_base"
SUPPORTED_EXTENSIONS = {".md", ".txt"}


@dataclass(frozen=True)
class KnowledgeChunk:
    source: str
    text: str


def retrieve_context(query: str, limit: int = 3) -> str:
    query_terms = _tokenize(query)
    if not query_terms:
        return ""

    scored_chunks = []
    for chunk in _load_chunks():
        score = _score_chunk(query_terms, chunk.text)
        if score > 0:
            scored_chunks.append((score, chunk))

    scored_chunks.sort(key=lambda item: item[0], reverse=True)
    return "\n\n".join(
        f"[{chunk.source}]\n{chunk.text}" for _, chunk in scored_chunks[:limit]
    )


def _load_chunks() -> list[KnowledgeChunk]:
    if not KNOWLEDGE_BASE_DIR.exists():
        return []

    chunks: list[KnowledgeChunk] = []
    for path in sorted(KNOWLEDGE_BASE_DIR.iterdir()):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            continue

        text = path.read_text(encoding="utf-8").strip()
        for index, chunk_text in enumerate(_split_chunks(text), start=1):
            chunks.append(KnowledgeChunk(source=f"{path.name}#{index}", text=chunk_text))

    return chunks


def _split_chunks(text: str) -> list[str]:
    chunks = [chunk.strip() for chunk in re.split(r"\n\s*\n", text) if chunk.strip()]
    return chunks or ([text] if text else [])


def _score_chunk(query_terms: set[str], text: str) -> int:
    text_terms = _tokenize(text)
    return len(query_terms & text_terms)


def _tokenize(text: str) -> set[str]:
    return {
        token
        for token in re.findall(r"[0-9A-Za-z가-힣]+", text.lower())
        if len(token) >= 2
    }
