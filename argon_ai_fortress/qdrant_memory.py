import os
import time
import hashlib
from pathlib import Path
from typing import List, Dict, Any, Optional
import httpx
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance,
    VectorParams,
    PointStruct,
)

OLLAMA_BASE_URL = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
EMBED_MODEL = "nomic-embed-text"
VECTOR_DIM = 768
COLLECTION_NAME = "argon_codebase_memory"


class ArgonQdrantMemory:
    """
    Yerel Qdrant Vektör Hafıza Motoru (Docker Gerektirmez, %100 Disk Tabanlı)
    Ollama 'nomic-embed-text' Batch GPU API kullanarak tüm proje kodlarını saniyeler içinde vektör uzayına gömer.
    """

    def __init__(self, storage_path: str = "./qdrant_storage"):
        self.storage_path = os.path.abspath(storage_path)
        os.makedirs(self.storage_path, exist_ok=True)
        self.client = QdrantClient(path=self.storage_path)
        self._ensure_collection()

    def _ensure_collection(self):
        collections = [c.name for c in self.client.get_collections().collections]
        if COLLECTION_NAME not in collections:
            self.client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=VectorParams(size=VECTOR_DIM, distance=Distance.COSINE),
            )

    def _fallback_vector(self, text: str) -> List[float]:
        h = hashlib.sha256(text.encode("utf-8", errors="ignore")).digest()
        vec = []
        for i in range(VECTOR_DIM):
            b = h[i % len(h)]
            vec.append(((b + i * 17) % 256) / 128.0 - 1.0)
        norm = sum(x * x for x in vec) ** 0.5 or 1.0
        return [x / norm for x in vec]

    def get_embedding(self, text: str) -> List[float]:
        return self.get_embeddings_batch([text])[0]

    def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Ollama /api/embed ile GPU üzerinde toplu (batch) 768-boyutlu vektör üretir."""
        cleaned = [t[:4000] for t in texts]
        try:
            with httpx.Client(timeout=30.0) as client:
                resp = client.post(
                    f"{OLLAMA_BASE_URL}/api/embed",
                    json={"model": EMBED_MODEL, "input": cleaned},
                )
                if resp.status_code == 200:
                    embs = resp.json().get("embeddings", [])
                    if len(embs) == len(texts) and len(embs[0]) == VECTOR_DIM:
                        return embs
        except Exception:
            pass
        return [self._fallback_vector(t) for t in texts]

    def index_directory(
        self,
        root_dir: str,
        extensions: Optional[List[str]] = None,
        max_files: int = 250,
    ) -> Dict[str, Any]:
        if extensions is None:
            extensions = [".dart", ".py", ".cpp", ".h", ".sql", ".md", ".yaml"]

        skip_dirs = {
            ".git",
            "build",
            ".dart_tool",
            "node_modules",
            "__pycache__",
            "qdrant_storage",
            "argon_ai_fortress",
            ".idea",
            ".gradle",
            "windows",
            "ios",
            "macos",
            "linux",
            "web",
        }

        indexed_count = 0
        chunks_count = 0
        start_time = time.time()

        batch_docs: List[str] = []
        batch_meta: List[Dict[str, Any]] = []

        root_path = Path(root_dir)
        if not root_path.exists():
            return {"status": "error", "message": f"Klasör bulunamadı: {root_dir}"}

        def flush_batch():
            nonlocal chunks_count
            if not batch_docs:
                return
            vectors = self.get_embeddings_batch(batch_docs)
            pts = []
            for vec, meta in zip(vectors, batch_meta):
                pts.append(
                    PointStruct(
                        id=meta["id"],
                        vector=vec,
                        payload=meta["payload"],
                    )
                )
            self.client.upsert(collection_name=COLLECTION_NAME, points=pts)
            chunks_count += len(pts)
            batch_docs.clear()
            batch_meta.clear()

        for dirpath, dirnames, filenames in os.walk(root_path):
            dirnames[:] = [d for d in dirnames if d not in skip_dirs]
            for fname in filenames:
                if indexed_count >= max_files:
                    break
                ext = os.path.splitext(fname)[1].lower()
                if ext not in extensions:
                    continue

                fpath = Path(dirpath) / fname
                try:
                    if fpath.stat().st_size > 250_000:
                        continue
                    content = fpath.read_text(encoding="utf-8", errors="ignore")
                    if not content.strip():
                        continue
                except Exception:
                    continue

                rel_path = str(fpath.relative_to(root_path)).replace("\\", "/")
                chunk_size = 1800
                overlap = 200
                for idx in range(0, len(content), chunk_size - overlap):
                    chunk = content[idx : idx + chunk_size]
                    if len(chunk.strip()) < 40:
                        continue

                    doc_text = f"Dosya: {rel_path}\n---\n{chunk}"
                    point_id_hex = hashlib.md5(
                        f"{rel_path}:{idx}".encode("utf-8")
                    ).hexdigest()
                    point_id = int(point_id_hex[:15], 16)

                    batch_docs.append(doc_text)
                    batch_meta.append(
                        {
                            "id": point_id,
                            "payload": {
                                "file_path": rel_path,
                                "full_path": str(fpath),
                                "chunk_index": idx,
                                "content": chunk,
                                "indexed_at": int(time.time()),
                            },
                        }
                    )

                    if len(batch_docs) >= 32:
                        flush_batch()

                indexed_count += 1

        flush_batch()

        elapsed = round(time.time() - start_time, 2)
        return {
            "status": "ok",
            "indexed_files": indexed_count,
            "total_chunks": chunks_count,
            "elapsed_seconds": elapsed,
            "storage_path": self.storage_path,
        }

    def search(self, query: str, top_k: int = 4) -> List[Dict[str, Any]]:
        query_vec = self.get_embedding(query)
        try:
            res = self.client.query_points(
                collection_name=COLLECTION_NAME,
                query=query_vec,
                limit=top_k,
            )
            hits = res.points
        except AttributeError:
            hits = self.client.search(
                collection_name=COLLECTION_NAME,
                query_vector=query_vec,
                limit=top_k,
            )

        results = []
        for h in hits:
            payload = h.payload or {}
            results.append(
                {
                    "score": round(float(h.score), 4),
                    "file_path": payload.get("file_path", ""),
                    "content": payload.get("content", ""),
                }
            )
        return results

    def stats(self) -> Dict[str, Any]:
        try:
            info = self.client.get_collection(COLLECTION_NAME)
            return {
                "collection": COLLECTION_NAME,
                "points_count": info.points_count,
                "status": str(info.status),
                "storage_path": self.storage_path,
            }
        except Exception as e:
            return {"collection": COLLECTION_NAME, "points_count": 0, "error": str(e)}
