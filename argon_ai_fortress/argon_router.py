import os
import re
import json
import time
import uuid
import asyncio
from pathlib import Path
from typing import List, Dict, Any, Optional
import httpx
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse, StreamingResponse
from pydantic import BaseModel

from qdrant_memory import ArgonQdrantMemory, OLLAMA_BASE_URL
import agent_tools

BASE_DIR = Path(__file__).parent.resolve()
STATIC_DIR = BASE_DIR / "static"
STATIC_DIR.mkdir(exist_ok=True)
CONFIG_PATH = BASE_DIR / "providers_config.json"

app = FastAPI(
    title="ARGON SOVEREIGN AI OS v4.0",
    description="Full Antigravity / Cursor Local Autonomous IDE & Multi-Agent System",
    version="4.0.0",
)

app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

memory = ArgonQdrantMemory(storage_path=str(BASE_DIR / "qdrant_storage"))

DEFAULT_CONFIG = {
    "routing_mode": "local_priority",
    "active_model": "qwen2.5-coder:7b",
    "use_rag_by_default": True,
    "custom_rules": "Yusuf gardaşıma her zaman samimi, net, mühendislik kalitesi yüksek ve eksiksiz çözümler üret.",
    "providers": {
        "pollinations_zero_key": {
            "name": "Pollinations AI (Sıfır Key - Açık Bulut)",
            "base_url": "https://text.pollinations.ai",
            "model": "openai",
            "api_key": "NONE_REQUIRED",
            "enabled": True,
        },
        "groq": {
            "name": "Groq (Llama 3.3 70B - 300+ tok/s)",
            "base_url": "https://api.groq.com/openai/v1",
            "model": "llama-3.3-70b-versatile",
            "api_key": "",
            "enabled": True,
        },
        "gemini": {
            "name": "Google Gemini 2.5 Flash (1M Context)",
            "base_url": "https://generativelanguage.googleapis.com/v1beta/openai",
            "model": "gemini-2.5-flash",
            "api_key": "",
            "enabled": True,
        },
        "cerebras": {
            "name": "Cerebras (Llama 3.1 8B - 800 tok/s)",
            "base_url": "https://api.cerebras.ai/v1",
            "model": "llama3.1-8b",
            "api_key": "",
            "enabled": True,
        },
        "openrouter": {
            "name": "OpenRouter (Qwen 2.5 Coder 32B Free)",
            "base_url": "https://openrouter.ai/api/v1",
            "model": "qwen/qwen-2.5-coder-32b-instruct:free",
            "api_key": "",
            "enabled": True,
        },
    },
}


def load_config() -> Dict[str, Any]:
    if CONFIG_PATH.exists():
        try:
            cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            for k, v in DEFAULT_CONFIG.items():
                if k not in cfg:
                    cfg[k] = v
            return cfg
        except Exception:
            pass
    save_config(DEFAULT_CONFIG)
    return DEFAULT_CONFIG.copy()


def save_config(cfg: Dict[str, Any]):
    CONFIG_PATH.write_text(
        json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8"
    )


def check_internet() -> bool:
    try:
        with httpx.Client(timeout=1.5) as client:
            return client.head("https://1.1.1.1").status_code < 500
    except Exception:
        return False


def check_ollama() -> Dict[str, Any]:
    try:
        with httpx.Client(timeout=2.0) as client:
            r = client.get(f"{OLLAMA_BASE_URL}/api/tags")
            if r.status_code == 200:
                models = [m.get("name") for m in r.json().get("models", [])]
                return {"online": True, "models": models}
    except Exception:
        pass
    return {"online": False, "models": []}


# --- TELEMETRY & STATUS ENDPOINTS ---


@app.get("/v1")
async def get_v1_root():
    return RedirectResponse(url="/")


@app.get("/v1/status")
async def get_status():
    cfg = load_config()
    return {
        "engine": "ARGON SOVEREIGN AI OS v4.0",
        "active_model": cfg.get("active_model", "qwen2.5-coder:7b"),
        "routing_mode": cfg.get("routing_mode", "local_priority"),
        "custom_rules": cfg.get("custom_rules", ""),
        "internet_online": check_internet(),
        "ollama": check_ollama(),
        "qdrant": memory.stats(),
        "gpu": agent_tools.get_hardware_telemetry(),
        "workspace": str(agent_tools.get_active_workspace()).replace("\\", "/"),
    }


@app.post("/v1/config")
async def update_config(request: Request):
    body = await request.json()
    cfg = load_config()
    for k in ["routing_mode", "active_model", "use_rag_by_default", "custom_rules"]:
        if k in body:
            cfg[k] = body[k]
    if "provider_keys" in body:
        for pk, kv in body["provider_keys"].items():
            if pk in cfg["providers"] and kv is not None:
                cfg["providers"][pk]["api_key"] = kv.strip()
    save_config(cfg)
    return {"status": "ok", "config": cfg}


# --- WORKSPACE, FILES, FOLDERS, GREP, GIT, DIFFS ---


@app.get("/v1/workspace/tree")
async def api_workspace_tree(path: str = ""):
    return agent_tools.list_workspace_tree(path)


@app.get("/v1/workspace/all_files")
async def api_workspace_all_files():
    return agent_tools.list_all_workspace_files(5000)


@app.post("/v1/workspace/native_pick")
async def api_native_pick(request: Request):
    body = await request.json()
    mode = body.get("mode", "files")
    ext_filter = body.get("ext_filter", "")
    return await asyncio.to_thread(agent_tools.pick_native_system_item, mode, ext_filter)


@app.post("/v1/workspace/switch")
async def api_workspace_switch(request: Request):
    body = await request.json()
    return agent_tools.set_active_workspace(body.get("workspace", ""))


@app.get("/v1/workspace/file")
async def api_read_file(path: str, start_line: int = 1, end_line: int = 2000):
    return agent_tools.read_workspace_file(path, start_line, end_line)


@app.post("/v1/workspace/file")
async def api_write_file(request: Request):
    body = await request.json()
    return agent_tools.write_workspace_file(
        body.get("path", ""), body.get("content", "")
    )


@app.post("/v1/workspace/folder")
async def api_create_folder(request: Request):
    body = await request.json()
    return agent_tools.create_workspace_folder(body.get("path", ""))


@app.post("/v1/workspace/delete")
async def api_delete_item(request: Request):
    body = await request.json()
    return agent_tools.delete_workspace_item(body.get("path", ""))


@app.post("/v1/workspace/rename")
async def api_rename_item(request: Request):
    body = await request.json()
    return agent_tools.rename_workspace_item(
        body.get("old_path", ""), body.get("new_name", "")
    )


@app.post("/v1/workspace/grep")
async def api_grep(request: Request):
    body = await request.json()
    return {
        "results": agent_tools.grep_workspace(
            body.get("query", ""),
            body.get("subpath", ""),
            max_results=80,
            ext_filter=body.get("ext_filter", ""),
        )
    }


@app.post("/v1/workspace/terminal")
async def api_terminal(request: Request):
    body = await request.json()
    return agent_tools.run_workspace_terminal(
        body.get("command", ""), body.get("cwd")
    )


@app.get("/v1/workspace/git")
async def api_git():
    return agent_tools.get_git_overview()


@app.get("/v1/workspace/diffs")
async def api_diffs():
    return {"diffs": agent_tools.get_recent_diffs(30)}


# --- SESSIONS API ---


@app.get("/v1/sessions")
async def api_list_sessions():
    return {"sessions": agent_tools.list_sessions()}


@app.post("/v1/sessions")
async def api_create_session(request: Request):
    body = await request.json()
    sid = body.get("id") or f"sess-{int(time.time()*1000)}"
    title = body.get("title") or "Yeni Görev Oturumu"
    model = body.get("model") or "qwen2.5-coder:7b"
    mode = body.get("mode") or "agent"
    agent_tools.create_session(sid, title, model, mode)
    return {"id": sid, "title": title}


@app.get("/v1/sessions/{session_id}")
async def api_get_session(session_id: str):
    return {"messages": agent_tools.get_session_messages(session_id)}


@app.delete("/v1/sessions/{session_id}")
async def api_delete_session(session_id: str):
    agent_tools.delete_session(session_id)
    return {"status": "ok"}


# --- QDRANT RAG API ---


@app.post("/v1/rag/search")
async def api_rag_search(request: Request):
    body = await request.json()
    q = body.get("query", "")
    top_k = int(body.get("top_k", 5))
    return {"query": q, "results": memory.search(q, top_k=top_k)}


@app.post("/v1/rag/index")
async def api_rag_index(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    ws = agent_tools.get_active_workspace()
    target = body.get("directory") or str(ws)
    return memory.index_directory(target, max_files=180)


# --- AUTONOMOUS AGENT ENGINE & TOOL PARSER ---

AGENT_SYSTEM_PROMPT = """Sen Yusuf'un yerel bilgisayarında çalışan **ARGON SOVEREIGN AI (Antigravity / Cursor OS v4.0)** otonom baş mühendisisin.
Aktif Çalışma Klasörü (Workspace): {workspace}
Özel Kurallar: {custom_rules}

DOĞRUDAN KULLANABİLECEĞİN OTONOM ARAÇLAR (Yanıtının içine bu etiketleri koyduğunda sistem anında çalıştırır):

1. Dosya Okuma:
<<<TOOL:READ_FILE>>>dosya/yolu.uzanti<<</TOOL:READ_FILE>>>

2. Klasör İçeriği Listeleme:
<<<TOOL:LIST_DIR>>>alt/klasor<<</TOOL:LIST_DIR>>>

3. Tüm Projede Kod/Metin Arama (Grep):
<<<TOOL:GREP_SEARCH>>>aranacak_kelime<<</TOOL:GREP_SEARCH>>>

4. Yeni Klasör Oluşturma:
<<<TOOL:CREATE_FOLDER>>>yeni/klasor/yolu<<</TOOL:CREATE_FOLDER>>>

5. Dosya Oluşturma veya Tamamını Yazma:
<<<TOOL:WRITE_FILE path="dosya/yolu.uzanti">>>
tam dosya icerigi buraya
<<</TOOL:WRITE_FILE>>>

6. Dosyada Hedef Bloğu Değiştirme (Diff Üretir):
<<<TOOL:EDIT_FILE path="dosya/yolu.uzanti">>>
<<<TARGET>>>
eski kod blogu
<<<REPLACEMENT>>>
yeni kod blogu
<<</TOOL:EDIT_FILE>>>

7. PowerShell Terminal Komutu Çalıştırma:
<<<TOOL:RUN_COMMAND>>>powershell komutu<<</TOOL:RUN_COMMAND>>>

KURALLAR:
- Yusuf'a her zaman samimi, delikanlı bir mühendis gibi ("Yusuf gardaşım") hitap et.
- Kullanıcı bir dosya oluşturmanı, düzenlemeni, klasör açmanı veya komut çalıştırmanı istediğinde lafla geçiştirme; doğrudan yukarıdaki <<<TOOL:...>>> etiketlerini kullanarak işlemi GERÇEKLEŞTİR!"""


def execute_parsed_tools(raw_text: str) -> List[Dict[str, Any]]:
    tasks = []

    # 1. CREATE_FOLDER
    for m in re.finditer(
        r"<<<TOOL:CREATE_FOLDER>>>(.*?)<<<[/]TOOL:CREATE_FOLDER>>>",
        raw_text,
        re.DOTALL,
    ):
        p = m.group(1).strip()
        if p:
            tasks.append((m.start(), "CREATE_FOLDER", p, None, None))

    # 2. LIST_DIR
    for m in re.finditer(
        r"<<<TOOL:LIST_DIR>>>(.*?)<<<[/]TOOL:LIST_DIR>>>", raw_text, re.DOTALL
    ):
        tasks.append((m.start(), "LIST_DIR", m.group(1).strip(), None, None))

    # 3. GREP_SEARCH
    for m in re.finditer(
        r"<<<TOOL:GREP_SEARCH>>>(.*?)<<<[/]TOOL:GREP_SEARCH>>>",
        raw_text,
        re.DOTALL,
    ):
        q = m.group(1).strip()
        if q:
            tasks.append((m.start(), "GREP_SEARCH", q, None, None))

    # 4. READ_FILE
    for m in re.finditer(
        r"<<<TOOL:READ_FILE>>>(.*?)<<<[/]TOOL:READ_FILE>>>", raw_text, re.DOTALL
    ):
        p = m.group(1).strip()
        if p:
            tasks.append((m.start(), "READ_FILE", p, None, None))

    # 5. WRITE_FILE
    for m in re.finditer(
        r'<<<TOOL:WRITE_FILE path="(.*?)">>>(.*?)<<<[/]TOOL:WRITE_FILE>>>',
        raw_text,
        re.DOTALL,
    ):
        p = m.group(1).strip()
        c = m.group(2).strip("\r\n")
        if p:
            tasks.append((m.start(), "WRITE_FILE", p, c, None))

    # 6. EDIT_FILE
    for m in re.finditer(
        r'<<<TOOL:EDIT_FILE path="(.*?)">>>(.*?)<<<[/]TOOL:EDIT_FILE>>>',
        raw_text,
        re.DOTALL,
    ):
        p = m.group(1).strip()
        body = m.group(2)
        tm = re.search(
            r"<<<TARGET>>>(.*?)<<<REPLACEMENT>>>(.*)", body, re.DOTALL
        )
        if p and tm:
            t_str = tm.group(1).strip("\r\n")
            r_str = tm.group(2).strip("\r\n")
            tasks.append((m.start(), "EDIT_FILE", p, t_str, r_str))

    # 7. RUN_COMMAND
    for m in re.finditer(
        r"<<<TOOL:RUN_COMMAND>>>(.*?)<<<[/]TOOL:RUN_COMMAND>>>",
        raw_text,
        re.DOTALL,
    ):
        cmd = m.group(1).strip()
        if cmd:
            tasks.append((m.start(), "RUN_COMMAND", cmd, None, None))

    # Kronolojik olarak sırala: Modelin ürettiği tam sırayla çalıştır
    tasks.sort(key=lambda x: x[0])

    results = []
    for pos, tool_type, arg1, arg2, arg3 in tasks:
        if tool_type == "CREATE_FOLDER":
            res = agent_tools.create_workspace_folder(arg1)
            results.append({
                "type": "CREATE_FOLDER",
                "target": arg1,
                "output": res.get("message") or res.get("error", "Klasör oluşturuldu"),
                "success": "error" not in res,
                "error": res.get("error"),
            })
        elif tool_type == "LIST_DIR":
            tree = agent_tools.list_workspace_tree(arg1)
            names = [
                f"{'[DIR] ' if x['is_dir'] else ''}{x['name']}"
                for x in tree.get("items", [])[:50]
            ]
            results.append({
                "type": "LIST_DIR",
                "target": arg1 or ".",
                "output": "\n".join(names),
                "success": True,
            })
        elif tool_type == "GREP_SEARCH":
            hits = agent_tools.grep_workspace(arg1, max_results=20)
            formatted = "\n".join(
                [f"{h['file']}:{h['line']}: {h['text']}" for h in hits]
            )
            results.append({
                "type": "GREP_SEARCH",
                "target": arg1,
                "output": formatted or "Eşleşme bulunamadı.",
                "success": True,
            })
        elif tool_type == "READ_FILE":
            r = agent_tools.read_workspace_file(arg1, 1, 300)
            has_err = "error" in r
            results.append({
                "type": "READ_FILE",
                "target": arg1,
                "output": (r.get("content") or r.get("error", ""))[:4000],
                "success": not has_err,
                "error": r.get("error"),
            })
        elif tool_type == "WRITE_FILE":
            w = agent_tools.write_workspace_file(arg1, arg2)
            has_err = "error" in w
            results.append({
                "type": "WRITE_FILE",
                "target": arg1,
                "output": w.get("diff") or w.get("error", "Yazıldı"),
                "success": not has_err,
                "error": w.get("error"),
            })
        elif tool_type == "EDIT_FILE":
            e_res = agent_tools.edit_workspace_file(arg1, arg2, arg3)
            has_err = "error" in e_res
            results.append({
                "type": "EDIT_FILE",
                "target": arg1,
                "output": e_res.get("diff") or e_res.get("error", ""),
                "success": not has_err,
                "error": e_res.get("error"),
            })
        elif tool_type == "RUN_COMMAND":
            t_res = agent_tools.run_workspace_terminal(arg1)
            out = (
                (t_res.get("stdout") or "") + "\n" + (t_res.get("stderr") or "")
            ).strip()
            ec = t_res.get("exit_code", 0)
            results.append({
                "type": "RUN_COMMAND",
                "target": arg1,
                "exit_code": ec,
                "output": out[:4000],
                "success": ec == 0,
                "error": t_res.get("stderr") if ec != 0 else None,
            })

    return results


def strip_tool_tags(text: str) -> str:
    cleaned = re.sub(
        r"<<<TOOL:.*?>>>.*?<<<[/]TOOL:.*?>>>", "", text, flags=re.DOTALL
    )
    return cleaned.strip()


async def call_llm_single(
    model: str, messages: List[Dict[str, str]], temperature: float = 0.25
) -> Dict[str, Any]:
    cfg = load_config()
    if model in ("pollinations:free", "cloud:pollinations"):
        async with httpx.AsyncClient(timeout=45.0) as client:
            r = await client.post(
                "https://text.pollinations.ai/",
                json={
                    "messages": messages,
                    "model": "openai",
                    "temperature": temperature,
                },
            )
            return {
                "content": r.text,
                "thinking": "",
                "tps": 0,
                "provider": "Pollinations Free Cloud",
            }

    if model.startswith("cloud:"):
        pkey = model.split(":", 1)[1]
        pinfo = cfg.get("providers", {}).get(pkey, {})
        akey = pinfo.get("api_key", "").strip()
        if akey:
            async with httpx.AsyncClient(timeout=45.0) as client:
                r = await client.post(
                    f"{pinfo['base_url']}/chat/completions",
                    headers={"Authorization": f"Bearer {akey}"},
                    json={
                        "model": pinfo["model"],
                        "messages": messages,
                        "temperature": temperature,
                    },
                )
                if r.status_code == 200:
                    d = r.json()
                    return {
                        "content": d["choices"][0]["message"]["content"],
                        "thinking": "",
                        "tps": 0,
                        "provider": pinfo["name"],
                    }

    # Default: Local Ollama RTX 4060
    async with httpx.AsyncClient(timeout=240.0) as client:
        r = await client.post(
            f"{OLLAMA_BASE_URL}/api/chat",
            json={
                "model": model,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": 3200,
                    "num_ctx": 8192,
                },
            },
        )
        if r.status_code == 200:
            data = r.json()
            raw = data.get("message", {}).get("content", "")
            ec = data.get("eval_count", 0)
            ed = data.get("eval_duration", 1) / 1e9
            tps = round(ec / ed, 1) if ed > 0 else 0
            thinking = ""
            tm = re.search(r"<think>(.*?)</think>", raw, re.DOTALL)
            if tm:
                thinking = tm.group(1).strip()
                raw = re.sub(
                    r"<think>.*?</think>", "", raw, flags=re.DOTALL
                ).strip()
            return {
                "content": raw,
                "thinking": thinking,
                "tps": tps,
                "provider": f"RTX 4060 ({model})",
            }
        raise RuntimeError(f"Ollama HTTP {r.status_code}: {r.text}")


class AgentRequest(BaseModel):
    session_id: Optional[str] = None
    message: str
    model: Optional[str] = "qwen2.5-coder:7b"
    mode: Optional[str] = "agent"  # "agent", "council", "chat"
    use_rag: Optional[bool] = True
    attached_files: Optional[List[str]] = []
    ext_filter: Optional[str] = ""


@app.post("/v1/agent/chat")
async def api_agent_chat(req: AgentRequest):
    start_ts = time.time()
    cfg = load_config()
    ws = str(agent_tools.get_active_workspace()).replace("\\", "/")

    sid = req.session_id or f"sess-{int(time.time()*1000)}"
    existing_msgs = agent_tools.get_session_messages(sid)
    if not existing_msgs:
        title = req.message[:42] + ("..." if len(req.message) > 42 else "")
        agent_tools.create_session(sid, title, req.model or "qwen2.5-coder:7b", req.mode or "agent")

    # 1. Eklenen @dosya, @klasör, *.uzantı ve PC yollarını kısıtlamasız çöz ve oku
    explicit_files = list(req.attached_files or [])
    for m in re.findall(r"@([a-zA-Z0-9_*?./\\:-]+)", req.message):
        if m not in explicit_files:
            explicit_files.append(m)

    resolved_targets = agent_tools.resolve_attached_targets(
        explicit_files, ext_filter=req.ext_filter or "", max_files=25
    )

    attached_context = ""
    for fp in resolved_targets:
        fdata = agent_tools.read_workspace_file(fp, 1, 500)
        if "content" in fdata:
            attached_context += f"\n\n[EKLENEN DOSYA: {fp}]\n```\n{fdata['content'][:4000]}\n```"

    # 2. Qdrant Derin Hafıza (RAG) - Eşik değeri 0.55'e yükseltildi (Gürültü önleme)
    rag_sources = []
    rag_context = ""
    if req.use_rag and memory.stats().get("points_count", 0) > 0:
        hits = memory.search(req.message, top_k=3)
        rel_hits = [h for h in hits if h["score"] > 0.55]
        if rel_hits:
            rag_sources = [h["file_path"] for h in rel_hits]
            rag_context = "\n\n[QDRANT VEKTÖR HAFIZASINDAN İLGİLİ KODLAR]:\n" + "\n\n".join(
                [f"📄 {h['file_path']} (Skor: {h['score']}):\n{h['content'][:800]}" for h in rel_hits]
            )

    # 3. Aider Esintili AST Proje Repo Haritası (Sınıflar & Fonksiyonlar)
    repo_map = agent_tools.generate_repo_map(max_symbols=80)
    repo_context = f"\n\n[PROJE MİMARİSİ VE REPO HARİTASI (AST ÖZETİ)]:\n```\n{repo_map}\n```" if repo_map else ""

    sys_prompt = (
        AGENT_SYSTEM_PROMPT.format(
            workspace=ws, custom_rules=cfg.get("custom_rules", "")
        )
        + repo_context
        + attached_context
        + rag_context
    )

    history_payload = [{"role": "system", "content": sys_prompt}]
    for m in existing_msgs[-8:]:
        history_payload.append({"role": m["role"], "content": m["content"]})
    history_payload.append({"role": "user", "content": req.message})

    agent_tools.add_message(sid, "user", req.message)

    all_tool_results = []
    council_steps = []
    thinking_out = ""
    final_reply = ""
    tps_out = 0
    used_model = req.model or "qwen2.5-coder:7b"

    try:
        if req.mode == "council":
            # KONSEY MODU: 1. Llama3.2 (Plan) -> 2. Qwen2.5-Coder (Kod & Araçlar) -> 3. DeepSeek-R1 (Denetim)
            plan_msgs = [
                {
                    "role": "system",
                    "content": f"Sen Konseyin Hızlı Stratejistisin (llama3.2:3b). Çalışma alanı: {ws}. Görevi analiz et ve 3 maddelik net teknik uygulama planı çıkar.",
                },
                {"role": "user", "content": req.message + attached_context},
            ]
            res1 = await call_llm_single("llama3.2:3b", plan_msgs, 0.2)
            council_steps.append(
                {
                    "agent": "⚡ Stratejist (llama3.2:3b)",
                    "tps": res1["tps"],
                    "content": res1["content"],
                }
            )

            coder_msgs = history_payload + [
                {
                    "role": "system",
                    "content": f"Stratejist Planı:\n{res1['content']}\nŞimdi Baş Kodlayıcı (qwen2.5-coder:7b) olarak kodu yaz ve gerekiyorsa <<<TOOL:...>>> etiketlerini çalıştır.",
                }
            ]
            res2 = await call_llm_single("qwen2.5-coder:7b", coder_msgs, 0.2)
            tools_step2 = execute_parsed_tools(res2["content"])
            all_tool_results.extend(tools_step2)
            clean_code_reply = strip_tool_tags(res2["content"])
            council_steps.append(
                {
                    "agent": "💻 Baş Kodlayıcı (qwen2.5-coder:7b)",
                    "tps": res2["tps"],
                    "content": clean_code_reply,
                }
            )

            audit_msgs = [
                {
                    "role": "system",
                    "content": "Sen Konseyin Baş Denetçisisin (deepseek-r1:8b). Yazılan çözümü güvenlik, performans ve mimari açıdan kısaca denetle ve son hükmü ver.",
                },
                {
                    "role": "user",
                    "content": f"Görev: {req.message}\n\nÜretilen Çözüm:\n{clean_code_reply}",
                },
            ]
            res3 = await call_llm_single("deepseek-r1:8b", audit_msgs, 0.3)
            thinking_out = res3.get("thinking", "")
            council_steps.append(
                {
                    "agent": "🔮 Baş Denetçi (deepseek-r1:8b)",
                    "tps": res3["tps"],
                    "content": res3["content"],
                }
            )

            final_reply = (
                f"### ⚡ 1. Stratejist Planı (`llama3.2:3b` - {res1['tps']} tok/s)\n{res1['content']}\n\n---\n\n"
                f"### 💻 2. Baş Mühendis Uygulaması (`qwen2.5-coder:7b` - {res2['tps']} tok/s)\n{clean_code_reply}\n\n---\n\n"
                f"### 🔮 3. Baş Denetçi Raporu (`deepseek-r1:8b` - {res3['tps']} tok/s)\n{res3['content']}"
            )
            tps_out = res2["tps"]
            used_model = "konsey-3-model"
        else:
            # TEKİL OTONOM AJAN MODU (ReAct Kendi Kendini Düzeltme & Çok Aşamalı Döngü - max 3 pas)
            max_turns = 3
            current_turn = 0
            all_replies = []

            while current_turn < max_turns:
                current_turn += 1
                res = await call_llm_single(used_model, history_payload, 0.25)
                cur_think = res.get("thinking", "")
                if cur_think:
                    if not thinking_out:
                        thinking_out = cur_think
                    else:
                        thinking_out += "\n---\n" + cur_think
                tps_out = res.get("tps", tps_out)
                raw_reply = res["content"]

                step_tools = execute_parsed_tools(raw_reply)
                all_tool_results.extend(step_tools)
                clean_text = strip_tool_tags(raw_reply)
                if clean_text:
                    all_replies.append(clean_text)

                # Eğer bu adımda hiçbir araç çağrılmadıysa görev bitti
                if not step_tools:
                    break

                # Araç çıktılarından geri bildirim üret
                feedbacks = []
                for t in step_tools:
                    if not t.get("success", True):
                        feedbacks.append(
                            f"❌ [BAŞARISIZ {t['type']} ({t['target']})]: {t.get('error') or t.get('output')}\n"
                            f"Öneri: Dosyayı tam görmek için <<<TOOL:READ_FILE>>>{t['target']}<<<[/]TOOL:READ_FILE>>> çalıştır veya <<<TOOL:WRITE_FILE path=\"{t['target']}\">>> ile baştan yaz."
                        )
                    else:
                        feedbacks.append(
                            f"✅ [BAŞARILI {t['type']} ({t['target']})]:\n{t.get('output', 'İşlem tamamlandı')}"
                        )

                feedback_str = "\n\n".join(feedbacks)
                history_payload.append({"role": "assistant", "content": raw_reply})
                history_payload.append(
                    {
                        "role": "user",
                        "content": (
                            f"Otonom araçlar çalıştırıldı. Sonuçlar:\n{feedback_str}\n\n"
                            "Lütfen sonuçları değerlendir. Varsa hataları düzelt veya bir sonraki adımı tamamla. "
                            "Tüm işlemler bittiyse Yusuf gardaşıma net özet bilgi ver."
                        ),
                    }
                )

            final_reply = "\n\n".join(all_replies).strip() or "Gardaşım otonom araç işlemleri başarıyla tamamlandı."

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

    elapsed = round(time.time() - start_ts, 2)
    meta_obj = {
        "model": used_model,
        "mode": req.mode,
        "elapsed_seconds": elapsed,
        "tokens_per_second": tps_out,
        "rag_sources": rag_sources,
        "tool_results": all_tool_results,
        "council_steps": council_steps,
    }
    agent_tools.add_message(sid, "assistant", final_reply, thinking_out, meta_obj)

    return {
        "session_id": sid,
        "reply": final_reply,
        "thinking": thinking_out,
        "model": used_model,
        "elapsed_seconds": elapsed,
        "tokens_per_second": tps_out,
        "rag_sources": rag_sources,
        "tool_results": all_tool_results,
        "council_steps": council_steps,
    }


# OpenAI Standart Uyumlu Endpoint (VS Code / Cursor / Oyun Motoru İçin)
@app.post("/v1/chat/completions")
async def openai_compatible_completions(request: Request):
    body = await request.json()
    msgs = body.get("messages", [])
    last_user = next(
        (m.get("content", "") for m in reversed(msgs) if m.get("role") == "user"),
        "",
    )
    model = body.get("model", "qwen2.5-coder:7b")
    if model in ("argon-auto", "default"):
        model = "qwen2.5-coder:7b"
    res = await api_agent_chat(
        AgentRequest(message=last_user, model=model, mode="agent")
    )
    if isinstance(res, JSONResponse):
        return res
    return {
        "id": f"chatcmpl-{int(time.time()*1000)}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": res["reply"]},
                "finish_reason": "stop",
            }
        ],
        "argon_meta": res,
    }


@app.get("/", response_class=HTMLResponse)
async def serve_studio():
    ui_file = BASE_DIR / "studio_ui.html"
    if ui_file.exists():
        return HTMLResponse(ui_file.read_text(encoding="utf-8"))
    return HTMLResponse("<h1>studio_ui.html yükleniyor...</h1>")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8090)
