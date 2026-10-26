import os
import re
import time
import json
import shutil
import sqlite3
import difflib
import subprocess
from pathlib import Path
from typing import Dict, Any, List, Optional

BASE_DIR = Path(__file__).parent.resolve()
DB_PATH = BASE_DIR / "argon_studio.db"
STATE_FILE = BASE_DIR / "workspace_state.json"
DEFAULT_WORKSPACE = BASE_DIR.parent.resolve()


def get_active_workspace() -> Path:
    if STATE_FILE.exists():
        try:
            data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
            p = Path(data.get("workspace", str(DEFAULT_WORKSPACE))).resolve()
            if p.exists() and p.is_dir() and len(p.parts) > 1:
                return p
        except Exception:
            pass
    return DEFAULT_WORKSPACE


def set_active_workspace(new_path: str) -> Dict[str, Any]:
    try:
        p = Path(new_path).resolve()
        if not p.exists() or not p.is_dir():
            return {"status": "error", "error": f"Klasör bulunamadı: {new_path}"}
        # C:\ kilitlenmesini engelle
        if len(p.parts) <= 1:
            p = DEFAULT_WORKSPACE
        STATE_FILE.write_text(
            json.dumps({"workspace": str(p).replace("\\", "/")}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        return {"status": "ok", "workspace": str(p).replace("\\", "/")}
    except Exception as e:
        return {"status": "error", "error": str(e)}


# --- SQLITE SESSIONS & DIFF HISTORY (WAL MODE + CONCURRENCY SAFE) ---


def get_db():
    conn = sqlite3.connect(str(DB_PATH), timeout=30.0)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    return conn


def init_db():
    conn = get_db()
    c = conn.cursor()
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS sessions (
            id TEXT PRIMARY KEY,
            title TEXT,
            model TEXT,
            mode TEXT,
            created_at INTEGER,
            updated_at INTEGER
        )
        """
    )
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT,
            role TEXT,
            content TEXT,
            thinking TEXT,
            meta_json TEXT,
            created_at INTEGER
        )
        """
    )
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS file_diffs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT,
            diff_text TEXT,
            action TEXT,
            created_at INTEGER
        )
        """
    )
    conn.commit()
    conn.close()


init_db()


def list_sessions() -> List[Dict[str, Any]]:
    conn = get_db()
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM sessions ORDER BY updated_at DESC LIMIT 50"
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def create_session(
    session_id: str, title: str, model: str = "qwen2.5-coder:7b", mode: str = "agent"
):
    now = int(time.time())
    conn = get_db()
    conn.execute(
        "INSERT OR REPLACE INTO sessions (id, title, model, mode, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
        (session_id, title, model, mode, now, now),
    )
    conn.commit()
    conn.close()


def delete_session(session_id: str):
    conn = get_db()
    conn.execute("DELETE FROM sessions WHERE id = ?", (session_id,))
    conn.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
    conn.commit()
    conn.close()


def add_message(
    session_id: str,
    role: str,
    content: str,
    thinking: str = "",
    meta: Optional[Dict[str, Any]] = None,
):
    now = int(time.time())
    conn = get_db()
    conn.execute(
        "INSERT INTO messages (session_id, role, content, thinking, meta_json, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (
            session_id,
            role,
            content,
            thinking or "",
            json.dumps(meta or {}, ensure_ascii=False),
            now,
        ),
    )
    conn.execute(
        "UPDATE sessions SET updated_at = ? WHERE id = ?", (now, session_id)
    )
    conn.commit()
    conn.close()


def get_session_messages(session_id: str) -> List[Dict[str, Any]]:
    conn = get_db()
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM messages WHERE session_id = ? ORDER BY id ASC",
        (session_id,),
    ).fetchall()
    conn.close()
    out = []
    for r in rows:
        d = dict(r)
        try:
            d["meta"] = json.loads(d.get("meta_json") or "{}")
        except Exception:
            d["meta"] = {}
        out.append(d)
    return out


def record_diff(file_path: str, old_text: str, new_text: str, action: str = "edit"):
    diff_lines = list(
        difflib.unified_diff(
            old_text.splitlines(keepends=True),
            new_text.splitlines(keepends=True),
            fromfile=f"a/{file_path}",
            tofile=f"b/{file_path}",
            n=3,
        )
    )
    diff_str = "".join(diff_lines)
    if not diff_str.strip() and action == "create":
        diff_str = f"+++ Yeni Dosya Oluşturuldu: {file_path} ({len(new_text)} bayt)"
    conn = get_db()
    conn.execute(
        "INSERT INTO file_diffs (file_path, diff_text, action, created_at) VALUES (?, ?, ?, ?)",
        (file_path, diff_str[:15000], action, int(time.time())),
    )
    conn.commit()
    conn.close()
    return diff_str


def get_recent_diffs(limit: int = 30) -> List[Dict[str, Any]]:
    conn = get_db()
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM file_diffs ORDER BY id DESC LIMIT ?", (limit,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# --- HARDWARE & GPU TELEMETRY ---


def get_hardware_telemetry() -> Dict[str, Any]:
    gpu_info = {
        "name": "NVIDIA GeForce RTX 4060",
        "temp_c": 0,
        "util_pct": 0,
        "mem_used_mb": 0,
        "mem_total_mb": 8188,
        "power_w": 0.0,
    }
    try:
        proc = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            parts = [x.strip() for x in proc.stdout.strip().split(",")]
            if len(parts) >= 6:
                gpu_info["name"] = parts[0]
                gpu_info["temp_c"] = int(float(parts[1]))
                gpu_info["util_pct"] = int(float(parts[2]))
                gpu_info["mem_used_mb"] = int(float(parts[3]))
                gpu_info["mem_total_mb"] = int(float(parts[4]))
                try:
                    gpu_info["power_w"] = round(float(parts[5]), 1)
                except Exception:
                    pass
    except Exception:
        pass
    return gpu_info


# --- SECURITY & TARGET RESOLUTION ---

SKIP_DIRS = {
    ".git",
    ".dart_tool",
    "node_modules",
    "__pycache__",
    ".venv",
    "venv",
    ".gradle",
}

BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".bmp",
    ".mp3", ".mp4", ".m4a", ".wav", ".ogg", ".webm", ".flac",
    ".zip", ".rar", ".7z", ".tar", ".gz",
    ".exe", ".dll", ".so", ".dylib", ".pdb", ".pyc", ".class", ".o", ".obj",
    ".ttf", ".woff", ".woff2", ".eot",
    ".db", ".sqlite", ".sqlite3", ".db-wal", ".db-shm",
}


def list_all_workspace_files(max_items: int = 8000, include_hidden: bool = True) -> Dict[str, Any]:
    """Projedeki tüm dosya, klasör ve uzantıları Katman Öncelikli (BFS) ve kısıtlamasız indeks olarak döndürür."""
    from collections import deque

    ws = get_active_workspace()
    results = []
    ext_counts: Dict[str, int] = {}
    count = 0
    queue = deque([ws])

    try:
        while queue and count < max_items:
            current_dir = queue.popleft()
            rel_root = ""
            try:
                r_path = current_dir.relative_to(ws)
                rel_root = "" if str(r_path) == "." else str(r_path).replace("\\", "/")
            except ValueError:
                continue

            try:
                entries = list(os.scandir(current_dir))
            except Exception:
                continue

            dirs = []
            files = []
            for e in entries:
                try:
                    if e.is_dir(follow_symlinks=False):
                        if e.name not in SKIP_DIRS and (include_hidden or not e.name.startswith(".")):
                            dirs.append(e)
                    else:
                        if not e.name.endswith((".pyc", ".db-wal", ".db-shm")):
                            files.append(e)
                except Exception:
                    continue

            dirs.sort(key=lambda x: x.name.lower())
            files.sort(key=lambda x: x.name.lower())

            for d in dirs:
                if count >= max_items:
                    break
                p = f"{rel_root}/{d.name}" if rel_root else d.name
                results.append({
                    "path": p,
                    "name": d.name,
                    "dir": rel_root or "/",
                    "ext": "[KLASÖR]",
                    "is_dir": True,
                    "size": 0,
                })
                count += 1
                queue.append(Path(d.path))

            for f in files:
                if count >= max_items:
                    break
                p = f"{rel_root}/{f.name}" if rel_root else f.name
                ext = os.path.splitext(f.name)[1].lower() or "(uzantısız)"
                ext_counts[ext] = ext_counts.get(ext, 0) + 1
                try:
                    sz = f.stat().st_size
                except Exception:
                    sz = 0
                results.append({
                    "path": p,
                    "name": f.name,
                    "dir": rel_root or "/",
                    "ext": ext,
                    "is_dir": False,
                    "size": sz,
                })
                count += 1
    except Exception as e:
        return {"error": str(e), "files": [], "extensions": []}

    sorted_exts = [
        {"ext": k, "count": v}
        for k, v in sorted(ext_counts.items(), key=lambda item: (-item[1], item[0]))
    ]
    parent_ws = str(ws.parent).replace("\\", "/") if ws.parent != ws else str(ws).replace("\\", "/")
    return {
        "workspace": str(ws).replace("\\", "/"),
        "parent_workspace": parent_ws,
        "total": len(results),
        "extensions": sorted_exts,
        "files": results,
    }


def pick_native_system_item(mode: str = "files", ext_filter: str = "") -> Dict[str, Any]:
    """Windows yerel Dosya veya Klasör Seçme penceresini açar (İstediğin uzantıyı veya klasörü PC'den seç)."""
    ws = str(get_active_workspace())
    try:
        if mode == "folder":
            ps_script = f"""
            Add-Type -AssemblyName System.Windows.Forms
            $f = New-Object System.Windows.Forms.FolderBrowserDialog
            $f.Description = 'Argon AI - İstediğin Klasörü Seç'
            $f.SelectedPath = '{ws}'
            $res = $f.ShowDialog()
            if ($res -eq [System.Windows.Forms.DialogResult]::OK) {{
                Write-Output $f.SelectedPath
            }}
            """
        else:
            # Kullanıcı özel uzantı girdiyse (örn: *.dart;*.py) filtreye ekle, yoksa Tüm Dosyalar (*.*)
            flt = "Tüm Dosyalar (*.*)|*.*|Kod & Metin (*.dart;*.py;*.js;*.ts;*.sql;*.json;*.yaml;*.html;*.css;*.md;*.txt;*.bat;*.ps1)|*.dart;*.py;*.js;*.ts;*.sql;*.json;*.yaml;*.html;*.css;*.md;*.txt;*.bat;*.ps1"
            if ext_filter and ext_filter.strip():
                clean_f = ext_filter.strip()
                if not clean_f.startswith("*"):
                    clean_f = f"*{clean_f}" if clean_f.startswith(".") else f"*.{clean_f}"
                flt = f"Özel Filtre ({clean_f})|{clean_f}|" + flt
            ps_script = f"""
            Add-Type -AssemblyName System.Windows.Forms
            $d = New-Object System.Windows.Forms.OpenFileDialog
            $d.InitialDirectory = '{ws}'
            $d.Filter = '{flt}'
            $d.Multiselect = $true
            $d.Title = 'Argon AI - İstediğin Dosyaları veya Uzantıları Seç'
            $res = $d.ShowDialog()
            if ($res -eq [System.Windows.Forms.DialogResult]::OK) {{
                $d.FileNames | ForEach-Object {{ Write-Output $_ }}
            }}
            """
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-STA", "-Command", ps_script],
            capture_output=True,
            text=True,
            timeout=120,
        )
        raw_lines = [
            ln.strip().replace("\\", "/")
            for ln in (proc.stdout or "").splitlines()
            if ln.strip()
        ]
        ws_norm = ws.replace("\\", "/").rstrip("/")
        rel_or_abs = []
        for p in raw_lines:
            if p.lower().startswith(ws_norm.lower() + "/"):
                rel_or_abs.append(p[len(ws_norm) + 1 :])
            else:
                rel_or_abs.append(p)
        return {"status": "ok", "selected": rel_or_abs}
    except Exception as e:
        return {"status": "error", "error": str(e), "selected": []}


def resolve_attached_targets(
    raw_targets: List[str], ext_filter: str = "", max_files: int = 25
) -> List[str]:
    """Dosya yolu, klasör yolu veya uzantı/joker (*.dart, .sql, lib/screens/*.dart) hedeflerini gerçek dosya listesine açar."""
    import fnmatch

    ws = get_active_workspace()
    allowed_exts = set()
    if ext_filter and ext_filter.strip():
        for part in re.split(r"[,;\s]+", ext_filter.strip()):
            p = part.strip().lower().lstrip("*")
            if p:
                if not p.startswith("."):
                    p = "." + p
                allowed_exts.add(p)

    resolved: List[str] = []

    def add_if_valid(fpath: Path):
        if len(resolved) >= max_files:
            return
        if not fpath.exists() or not fpath.is_file():
            return
        ext = fpath.suffix.lower()
        if allowed_exts and ext not in allowed_exts:
            return
        try:
            rel = str(fpath.relative_to(ws)).replace("\\", "/")
        except ValueError:
            rel = str(fpath.resolve()).replace("\\", "/")
        if rel not in resolved:
            resolved.append(rel)

    for item in raw_targets:
        t = item.strip().lstrip("@")
        if not t:
            continue
        # Sadece ".dart" veya "*.dart" gibi uzantı/glob yazıldıysa
        if t.startswith(".") and "/" not in t and "\\" not in t and not (ws / t).exists():
            t = f"*{t}"

        if "*" in t or "?" in t:
            pattern = t.replace("\\", "/").lower()
            for root, dirs, files in os.walk(ws):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                for f in files:
                    fp = Path(root) / f
                    rel = str(fp.relative_to(ws)).replace("\\", "/")
                    if fnmatch.fnmatch(rel.lower(), pattern) or fnmatch.fnmatch(f.lower(), pattern):
                        add_if_valid(fp)
                        if len(resolved) >= max_files:
                            break
                if len(resolved) >= max_files:
                    break
            continue

        target_path = resolve_target(t)
        if target_path.exists():
            if target_path.is_file():
                add_if_valid(target_path)
            elif target_path.is_dir():
                for root, dirs, files in os.walk(target_path):
                    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                    for f in sorted(files):
                        fp = Path(root) / f
                        if fp.suffix.lower() in BINARY_EXTS and not allowed_exts:
                            continue
                        add_if_valid(fp)
                        if len(resolved) >= max_files:
                            break
                    if len(resolved) >= max_files:
                        break

    return resolved


def resolve_target(rel_or_abs: str) -> Path:
    ws = get_active_workspace()
    if not rel_or_abs:
        return ws
    p = Path(rel_or_abs)
    if not p.is_absolute():
        p = (ws / rel_or_abs).resolve()
    else:
        p = p.resolve()

    # Güvenlik Kontrolü: C:\ kökünü engelle, çalışma alanı sınırını koru
    if str(p).lower() == "c:\\":
        return ws
    return p


def strip_markdown_fences(code: str) -> str:
    """Modelin kazara eklediği ```dart ... ``` sarmalamalarını ve satır numaralarını temizler."""
    c = code.strip()
    c = re.sub(r"^```[a-zA-Z0-9_+-]*\r?\n", "", c)
    c = re.sub(r"\r?\n```$", "", c)
    lines = c.splitlines()
    if lines and all(re.match(r"^\s*\d+\s*\|\s?", ln) for ln in lines if ln.strip()):
        lines = [re.sub(r"^\s*\d+\s*\|\s?", "", ln) for ln in lines]
        c = "\n".join(lines)
    return c.strip("\r\n")


# --- FILE & FOLDER CRUD WITH SMART NORMALIZATION ---


def list_workspace_tree(subpath: str = "") -> Dict[str, Any]:
    ws = get_active_workspace()
    target = resolve_target(subpath)
    if not target.exists() or not target.is_dir():
        target = ws

    items = []
    try:
        for entry in os.scandir(target):
            if entry.name in SKIP_DIRS:
                continue
            is_dir = entry.is_dir()
            try:
                rel = str(Path(entry.path).relative_to(ws)).replace("\\", "/")
            except ValueError:
                rel = str(Path(entry.path)).replace("\\", "/")
            size = entry.stat().st_size if not is_dir else 0
            mtime = int(entry.stat().st_mtime)
            items.append(
                {
                    "name": entry.name,
                    "path": rel,
                    "abs_path": str(Path(entry.path).resolve()).replace("\\", "/"),
                    "is_dir": is_dir,
                    "size": size,
                    "mtime": mtime,
                }
            )
    except Exception as e:
        return {"error": str(e), "items": []}

    items.sort(key=lambda x: (not x["is_dir"], x["name"].lower()))
    parent_path = ""
    if target != ws and target.parent != target:
        try:
            parent_path = str(target.parent.relative_to(ws)).replace("\\", "/")
            if parent_path == ".":
                parent_path = ""
        except ValueError:
            parent_path = str(target.parent).replace("\\", "/")

    return {
        "workspace": str(ws).replace("\\", "/"),
        "current_dir": str(target).replace("\\", "/"),
        "parent_path": parent_path,
        "can_go_up": target != ws and target.parent != target,
        "up_abs_path": str(target.parent).replace("\\", "/"),
        "items": items,
    }


def read_workspace_file(
    rel_path: str, start_line: int = 1, end_line: int = 5000, with_line_numbers: bool = False
) -> Dict[str, Any]:
    target = resolve_target(rel_path)
    if not target.exists() or not target.is_file():
        return {"error": f"Dosya bulunamadı: {rel_path}"}

    try:
        raw_text = target.read_text(encoding="utf-8", errors="ignore")
        all_lines = raw_text.splitlines()
        total_lines = len(all_lines)
        s = max(1, start_line) - 1
        e = min(total_lines, end_line)
        selected_lines = all_lines[s:e]

        if with_line_numbers:
            numbered = [f"{s + idx + 1:4d} | {line}" for idx, line in enumerate(selected_lines)]
            content_str = "\n".join(numbered)
        else:
            content_str = "\n".join(selected_lines)

        truncation_note = ""
        if e < total_lines:
            truncation_note = f"\n[... TRUNCATED: Dosya {total_lines - e} satır daha devam ediyor. İlerisini görmek için start_line={e+1} iste ...] "

        return {
            "path": rel_path,
            "abs_path": str(target).replace("\\", "/"),
            "content": content_str + truncation_note,
            "raw_content": raw_text,
            "total_lines": total_lines,
            "start_line": s + 1,
            "end_line": e,
            "size_bytes": target.stat().st_size,
        }
    except Exception as e:
        return {"error": str(e)}


def write_workspace_file(rel_path: str, content: str) -> Dict[str, Any]:
    target = resolve_target(rel_path)
    cleaned_content = strip_markdown_fences(content)
    try:
        old_text = ""
        action = "create"
        if target.exists() and target.is_file():
            old_text = target.read_text(encoding="utf-8", errors="ignore")
            action = "write"
        target.parent.mkdir(parents=True, exist_ok=True)
        # Orijinal newline biçimini koru
        newline_char = "\r\n" if "\r\n" in old_text else "\n"
        normalized = cleaned_content.replace("\r\n", "\n").replace("\n", newline_char)
        with open(target, "w", encoding="utf-8", newline="") as f:
            f.write(normalized)

        diff_str = record_diff(rel_path, old_text, normalized, action=action)
        return {
            "status": "ok",
            "path": rel_path,
            "abs_path": str(target).replace("\\", "/"),
            "bytes_written": len(normalized.encode("utf-8")),
            "diff": diff_str,
        }
    except Exception as e:
        return {"error": str(e)}


def edit_workspace_file(
    rel_path: str, target_str: str, replacement_str: str
) -> Dict[str, Any]:
    """
    Akıllı, esnek kod bloğu değiştirici.
    Markdown çitlerini temizler, newline normalizasyonu yapar ve girinti toleransı uygular.
    """
    target = resolve_target(rel_path)
    if not target.exists() or not target.is_file():
        return {"error": f"Düzenlenecek dosya bulunamadı: {rel_path}"}

    try:
        raw_bytes = target.read_bytes()
        is_crlf = b"\r\n" in raw_bytes
        old_text = raw_bytes.decode("utf-8", errors="ignore").replace("\r\n", "\n")

        clean_target = strip_markdown_fences(target_str).replace("\r\n", "\n").strip("\n")
        clean_replacement = strip_markdown_fences(replacement_str).replace("\r\n", "\n")

        # 1. Aşama: Doğrudan alt-dize eşleşmesi
        if clean_target in old_text:
            new_text = old_text.replace(clean_target, clean_replacement, 1)
        else:
            # 2. Aşama: Satır bazlı boşluk/girinti toleranslı arama
            target_lines = [l.strip() for l in clean_target.splitlines() if l.strip()]
            file_lines = old_text.splitlines()
            match_start = -1
            match_len = 0

            if target_lines:
                for idx in range(len(file_lines) - len(target_lines) + 1):
                    subset = [file_lines[idx + j].strip() for j in range(len(target_lines))]
                    if subset == target_lines:
                        match_start = idx
                        match_len = len(target_lines)
                        break

            if match_start != -1:
                # Orijinal dosyadaki girintiyi koru
                leading_spaces = len(file_lines[match_start]) - len(file_lines[match_start].lstrip())
                rep_lines = [(" " * leading_spaces + l.lstrip()) for l in clean_replacement.splitlines()]
                file_lines[match_start : match_start + match_len] = rep_lines
                new_text = "\n".join(file_lines)
            else:
                return {
                    "error": f"Hedef blok dosyada bulunamadı ({rel_path}). Lütfen dosyanın güncel içeriğini kontrol edip hedefi tekrar verin."
                }

        # Dosyayı kaydet
        newline_char = "\r\n" if is_crlf else "\n"
        final_save = new_text.replace("\n", newline_char)
        with open(target, "w", encoding="utf-8", newline="") as f:
            f.write(final_save)

        diff_str = record_diff(rel_path, old_text, new_text, action="edit")
        return {
            "status": "ok",
            "path": rel_path,
            "diff": diff_str,
        }
    except Exception as e:
        return {"error": str(e)}


def create_workspace_folder(rel_path: str) -> Dict[str, Any]:
    target = resolve_target(rel_path)
    try:
        target.mkdir(parents=True, exist_ok=True)
        return {"status": "ok", "path": str(target).replace("\\", "/")}
    except Exception as e:
        return {"error": str(e)}


def delete_workspace_item(rel_path: str) -> Dict[str, Any]:
    target = resolve_target(rel_path)
    ws = get_active_workspace()
    # Sandbox Koruması
    if not str(target).startswith(str(ws)) or target == ws:
        return {"error": "Güvenlik: Çalışma alanı dışındaki veya kök dizin silinemez."}
    if not target.exists():
        return {"error": f"Silinecek öğe bulunamadı: {rel_path}"}

    try:
        if target.is_dir():
            shutil.rmtree(target)
        else:
            old_text = target.read_text(encoding="utf-8", errors="ignore")
            target.unlink()
            record_diff(rel_path, old_text, "", action="delete")
        return {"status": "ok", "deleted": rel_path}
    except Exception as e:
        return {"error": str(e)}


def rename_workspace_item(old_path: str, new_name: str) -> Dict[str, Any]:
    target = resolve_target(old_path)
    ws = get_active_workspace()
    if not str(target).startswith(str(ws)) or target == ws:
        return {"error": "Güvenlik engeli."}
    if not target.exists():
        return {"error": f"Öğe bulunamadı: {old_path}"}
    try:
        new_target = target.parent / new_name
        target.rename(new_target)
        return {
            "status": "ok",
            "old_path": old_path,
            "new_path": str(new_target).replace("\\", "/"),
        }
    except Exception as e:
        return {"error": str(e)}


# --- AIDER-STYLE REPO MAP (AST / SYMBOL EXTRACTOR) ---


def generate_repo_map(max_symbols: int = 45) -> str:
    """Aider benzeri repo haritası: Projedeki ana sınıfları, fonksiyonları ve yapıları özetler."""
    ws = get_active_workspace()
    symbols = []
    class_regex = re.compile(r"^\s*(class|struct|enum|interface)\s+([A-Za-z0-9_]+)", re.MULTILINE)
    func_regex = re.compile(r"^\s*(def|void|Future|Widget|String|int|bool|async\s+def)\s+([A-Za-z0-9_]+)\s*\(", re.MULTILINE)

    exts = {".dart", ".py", ".sql", ".js", ".ts", ".cpp", ".h"}
    for dirpath, dirnames, filenames in os.walk(ws):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and d not in {"build", ".dart_tool"}]
        for fname in filenames:
            if os.path.splitext(fname)[1].lower() not in exts:
                continue
            fpath = Path(dirpath) / fname
            try:
                rel = str(fpath.relative_to(ws)).replace("\\", "/")
                content = fpath.read_text(encoding="utf-8", errors="ignore")
                found_in_file = []
                for m in class_regex.finditer(content):
                    found_in_file.append(f"{m.group(1)} {m.group(2)}")
                for m in func_regex.finditer(content):
                    found_in_file.append(f"{m.group(2)}()")
                if found_in_file:
                    symbols.append(f"📄 {rel}: " + ", ".join(found_in_file[:5]))
                if len(symbols) >= max_symbols:
                    break
            except Exception:
                continue
        if len(symbols) >= max_symbols:
            break

    return "\n".join(symbols)


# --- GREP & TERMINAL & GIT ---


def grep_workspace(
    query: str, subpath: str = "", max_results: int = 80, ext_filter: str = ""
) -> List[Dict[str, Any]]:
    ws = get_active_workspace()
    root = resolve_target(subpath)
    if not query.strip() or not root.exists():
        return []

    allowed_exts = set()
    if ext_filter and ext_filter.strip():
        for part in re.split(r"[,;\s]+", ext_filter.strip()):
            p = part.strip().lower().lstrip("*")
            if p:
                if not p.startswith("."):
                    p = "." + p
                allowed_exts.add(p)

    results = []
    try:
        pattern = re.compile(query, re.IGNORECASE)
    except Exception:
        pattern = re.compile(re.escape(query), re.IGNORECASE)

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and d not in {"build", ".dart_tool"}]
        for fname in filenames:
            if len(results) >= max_results:
                return results
            f_ext = os.path.splitext(fname)[1].lower()
            if allowed_exts:
                if f_ext not in allowed_exts:
                    continue
            elif f_ext in BINARY_EXTS:
                continue
            fpath = Path(dirpath) / fname
            try:
                if fpath.stat().st_size > 600_000:
                    continue
                lines = fpath.read_text(encoding="utf-8", errors="ignore").splitlines()
                try:
                    rel = str(fpath.relative_to(ws)).replace("\\", "/")
                except ValueError:
                    rel = str(fpath).replace("\\", "/")
                for idx, line in enumerate(lines, 1):
                    if pattern.search(line):
                        results.append(
                            {
                                "file": rel,
                                "line": idx,
                                "text": line.strip()[:240],
                            }
                        )
                        if len(results) >= max_results:
                            return results
            except Exception:
                continue
    return results


def run_workspace_terminal(
    command: str, cwd_override: Optional[str] = None, timeout_sec: int = 35
) -> Dict[str, Any]:
    cwd = str(resolve_target(cwd_override)) if cwd_override else str(get_active_workspace())
    start_t = time.time()
    try:
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-Command", command],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
        )
        return {
            "command": command,
            "cwd": cwd,
            "exit_code": proc.returncode,
            "stdout": proc.stdout[:15000],
            "stderr": proc.stderr[:8000],
            "elapsed": round(time.time() - start_t, 2),
        }
    except subprocess.TimeoutExpired:
        return {
            "command": command,
            "cwd": cwd,
            "exit_code": -1,
            "stdout": "",
            "stderr": f"Komut zaman aşımına uğradı ({timeout_sec}s).",
            "elapsed": timeout_sec,
        }
    except Exception as e:
        return {
            "command": command,
            "cwd": cwd,
            "exit_code": -1,
            "stdout": "",
            "stderr": str(e),
            "elapsed": 0,
        }


def get_git_overview() -> Dict[str, Any]:
    status_res = run_workspace_terminal("git status --short", timeout_sec=5)
    branch_res = run_workspace_terminal("git branch --show-current", timeout_sec=5)
    log_res = run_workspace_terminal('git log -n 8 --pretty=format:"%h|%an|%ar|%s"', timeout_sec=5)
    commits = []
    for line in (log_res.get("stdout") or "").splitlines():
        parts = line.split("|", 3)
        if len(parts) == 4:
            commits.append(
                {
                    "hash": parts[0],
                    "author": parts[1],
                    "date": parts[2],
                    "message": parts[3],
                }
            )
    changed_files = []
    for line in (status_res.get("stdout") or "").splitlines():
        if len(line) > 3:
            changed_files.append({"status": line[:2].strip(), "file": line[3:].strip()})
    return {
        "branch": (branch_res.get("stdout") or "main").strip(),
        "changed_files": changed_files,
        "commits": commits,
    }
