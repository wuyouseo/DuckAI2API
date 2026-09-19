<div align="center">

# 🦆 DuckAI2API

**Turn Duck.ai into an OpenAI / Anthropic / Responses compatible API — for free.**


[🇨🇳 中文](./README.zh.md) · [🇬🇧 English](./README.md)

</div>

---

A relay service that speaks **three** LLM protocols at once, backed by **Duck.ai** (`https://duck.ai/`) — no API key, no payment. Built from a live reverse-engineering of Duck.ai's real-time web protocol (XHR + SSE, no official API), re-verified after every major site change.

Works as a drop-in backend for **Claude Code**, the **OpenAI SDK**, the **OpenAI Responses API**, and third-party IDEs such as WorkBuddy. All chat comes from Duck.ai's genuine SSE stream.

### Demo

| Third-party IDE (WorkBuddy) chat | Code generation task |
|---|---|
| ![chat demo](docs/images/demo-chat.png) | ![code demo](docs/images/demo-code.png) |

**GPT Image 2 generation** (`/v1/images/generations`, prompt: *a shiba inu wearing a red scarf sitting in the snow, pine trees and falling snow in the background, warm light, HD photography style*):

![image demo](docs/images/demo-image.jpg)

## ✨ Why this exists

Duck.ai has no public API. Its chat runs over:

- `GET https://duck.ai/duckchat/v1/models` — public model catalog (with free/paid tiers and capability flags; the relay lists models dynamically from it)
- `POST https://duck.ai/duckchat/v1/chat` with header `Accept: text/event-stream` — the SSE chat stream, token by token as `data: {"action":"success","message":"…"}`, ending with `data: [DONE]`
- Chat requests must carry anti-bot tokens such as `x-fe-signals` / `X-Vqd-Hash-1` that are minted live by the page JS and **cannot be replayed offline**; that is why the relay drives the page's own send logic through a real Chrome instance (see the top-level comments in `duckai.py`)

Model ids are sent in the JSON body as `model: "<model>"`. The relay maps friendly model names to these ids.

## 🚀 Features

| | Capability |
|---|---|
| 🧠 **Dynamic free models** | Live catalog: GPT-5.6 Luna, GPT-5.4 mini, Claude Haiku 4.5, Mistral Small, gpt-oss 120B, Gemma 4 31B, and more |
| 🔌 **Triple protocol** | `/v1/chat/completions` (OpenAI), `/v1/messages` (Anthropic), `/v1/responses` (OpenAI Responses) |
| 🖼️ **Image generation** | `/v1/images/generations` (OpenAI shape): drives GPT-5.6 Luna's native `GenerateImage` (GPT Image 2 backend), returns `b64_json` or a local `url` |
| 🌊 **Real streaming** | Every protocol streams at Duck.ai SSE's native token granularity |
| ♻️ **Session reuse** | Follow-up turns reuse the warmed-up page and Duck.ai's native multi-turn context, saving ~7s of warmup per request |
| 🧮 **Reasoning-tier passthrough** | `reasoning_effort` (OpenAI) / `thinking` (Anthropic) mapped to Duck.ai's `reasoningEffort`, with automatic fallback when the server-side rewrite fails |
| 🤖 **Agent tool loop (experimental)** | Requires `DUCKAI_TOOL_ROUTING=1`: synthesizes `tool_use` / `tool_calls` / `function_call` from user intent and feeds `tool_result` back to Duck.ai. **The server NEVER executes commands** |
| 🔄 **Session rotation** | Per-model headless-Chrome sessions, auto-rebuilt on rate-limit / crash |
| 🔐 **Optional key wall** | Set `DUCKAI_API_KEY`; clients present `Authorization: Bearer <key>` |
| 🪟 **Cross-platform** | Windows · macOS · Linux |

## 📦 Models

`/v1/models` pulls Duck.ai's `GET /duckchat/v1/models` live, including `access` (free/paid) and `capabilities` (image upload, reasoning tiers, tools) flags. As of 2026-09-19:

| id                     | Name            | Tier |
|------------------------|-----------------|------|
| `gpt-5.6-luna`         | GPT-5.6 Luna    | free |
| `gpt-5.4-mini`         | GPT-5.4 mini    | free |
| `claude-haiku-4-5`     | Claude Haiku 4.5| free |
| `mistral-small-2603`   | Mistral Small 4 | free |
| `tinfoil/gpt-oss-120b` | gpt-oss 120B    | free |
| `tinfoil/gemma4-31b`   | Gemma 4 31B     | free |
| `gpt-5.6-terra` / `gpt-5.6-sol` | GPT-5.6 Terra / Sol | paid (plus/pro) |
| `claude-sonnet-4-6` / `claude-opus-4-8` | Claude Sonnet 4.6 / Opus 4.8 | paid (plus/pro) |

> The legacy `gpt-5.4` (non-mini) was retired on 2026-09-18; aliases like `gpt-5.4` / `gpt-4o` now resolve to `gpt-5.4-mini`. Paid-tier models can still be sent through the relay (using your browser's Duck.ai identity); whether Duck.ai lets them through is up to Duck.ai.

Unknown model ids pass through verbatim (future Duck.ai models work without a code change). Common aliases (`gpt-5.6`, `claude-haiku`, `o3-mini`, …) resolve to the table above.

Open `http://localhost:8080/v1/models` in a browser to see the live catalog (with `access` tiers and `capabilities` flags):

![models list](docs/images/models-list.png)

## 🛠️ Requirements

- **Python** ≥ 3.10
- **Google Chrome (stable)** installed on the host. The relay drives Duck.ai through a real Chrome instance (`Playwright` `channel="chrome"`); the bundled Playwright Chromium is fingerprint-banned by Duck.ai, so system Chrome is required. You do **not** need to run `playwright install chromium`.
  - Windows: install from <https://www.google.com/chrome/>
  - macOS: `brew install --cask google-chrome`
  - Linux (Debian/Ubuntu): `sudo apt-get install google-chrome-stable`
- If Chrome is not at the default path, point `DUCKAI_CHROME_PATH` at the binary.

## ⚡ Quick start

```bash
# 1. virtualenv
python3 -m venv .venv
#    Windows:        .venv\Scripts\activate
#    macOS / Linux:  source .venv/bin/activate

# 2. deps
pip install -r requirements.txt

# 3. (optional) config
cp example.env .env             # API key, proxy, etc.

# 4. serve
python -m uvicorn main:app --host 0.0.0.0 --port 8080
#    On Windows you can also double-click start.bat (stop.bat to stop)
```

Server listens on `http://localhost:8080` (override with `PORT`). Verify: opening `http://localhost:8080/v1/models` in a browser should return the model JSON list.

## ⚙️ Configuration

All settings are optional and read from environment variables (`.env` loaded via `python-dotenv`).

| Variable                | Meaning                                                                                       | Default              |
|-------------------------|-----------------------------------------------------------------------------------------------|----------------------|
| `DUCKAI_API_KEY`        | Bearer token required on all `/v1` requests. **Empty = open access.**                         | *(empty)*            |
| `DUCKAI_BASE`           | Duck.ai host.                                                                                 | `https://duck.ai`    |
| `DUCKAI_MODEL`          | Default model when the client omits one.                                                      | `gpt-5.6-luna`       |
| `DUCKAI_NEW_CHAT`       | `1` = fresh chat per request (stateless); `0` = keep session history.                         | `0`                  |
| `DUCKAI_TOOL_ROUTING`   | `1` = enable intent→tool synthesis. **Off by default**: agent clients (WorkBuddy/Claude Code) always send `tools` + huge context, and a regex false-hit returns `content:null`, which IDEs report as "model unresponsive". | `0`                  |
| `DUCKAI_PROXIES`        | Comma-separated proxy pool; rotates past per-IP `ERR_BN_LIMIT` bans.                          | *(none)*             |
| `DUCKAI_PROXY`          | Single proxy (alternative to the pool).                                                       | *(none)*             |
| `DUCKAI_MAX_CONCURRENCY`| Max in-flight requests per proxy before queuing.                                              | `2`                  |
| `DUCKAI_CHROME_PATH`    | Override the path to the Google Chrome binary (auto-detected per OS otherwise).               | per-OS default       |
| `PORT`                  | Server port.                                                                                  | `8080`               |

## 💡 Usage examples

### OpenAI SDK (streaming)

```python
from openai import OpenAI
c = OpenAI(base_url="http://localhost:8080/v1", api_key="t")  # any key if the wall is off
stream = c.chat.completions.create(
    model="gpt-5.6-luna",
    messages=[{"role": "user", "content": "Explain quantum tunneling in one sentence."}],
    stream=True,
)
for chunk in stream:
    print(chunk.choices[0].delta.content or "", end="", flush=True)
```

### Anthropic SDK (Claude Code)

```python
from anthropic import Anthropic
c = Anthropic(base_url="http://localhost:8080", api_key="t")
c.messages.create(
    model="gpt-5.6-luna",
    max_tokens=1024,
    messages=[{"role": "user", "content": "What is 2+2?"}],
)
```

Point Claude Code at the relay with `ANTHROPIC_BASE_URL=http://localhost:8080` and `ANTHROPIC_API_KEY=t`.

### Third-party IDE integration (WorkBuddy and other OpenAI-compatible clients)

In the IDE's "custom model / provider" settings, fill in:

| Field | Value |
|---|---|
| Base URL | `http://localhost:8080/v1` (**OpenAI protocol requires the `/v1` suffix**) |
| API Key | any value (e.g. `123`; not checked when `DUCKAI_API_KEY` is empty in `.env`) |
| Model name | `gpt-5.6-luna` / `claude-haiku-4-5` / `gpt-5.4-mini`, etc. (see the model table above) |
| Request timeout | ≥60 seconds recommended (the first cold-start turn includes ~7–15s of Chrome warmup) |

![IDE config](docs/images/ide-config.png)

> Note: agent mode carries `tools` plus tens of thousands of characters of context. Duck.ai's composer has a hard cap of ~12K characters; the excess is automatically truncated by the relay (keeping the system-instruction head + the latest question), so it suits Q&A and light tasks — not heavy agent workflows that need whole-repo understanding.

### Tool loop (experimental, off by default)

Set `DUCKAI_TOOL_ROUTING=1` in `.env` first. Send `tools` just like you would to Claude; the relay emits a `tool_use` block from the user's intent, your agent executes it locally and returns the `tool_result`, and the relay forwards it to Duck.ai for a grounded final answer. **Why it's off by default**: agent clients (WorkBuddy / Claude Code, etc.) always attach `tools` and tens of thousands of characters of context, and a regex false-hit returns a synthesized `content:null` response that IDEs judge as "model unresponsive". When disabled, requests carrying `tools` go through Duck.ai as plain chat.

```python
tools=[{"name":"Read","description":"Read a file",
        "input_schema":{"type":"object","properties":{"file_path":{"type":"string"}}}}]
# user: "Read README.md"  ->  relay returns tool_use: Read {file_path:"README.md"}
# agent runs Read locally, returns tool_result; relay answers using that content.
```

### Image generation (OpenAI Images shape)

Duck.ai has no standalone image API — GPT-5.6 Luna natively calls `GenerateImage` (GPT Image 2 backend) inside a chat turn. The relay drives that turn and extracts the full base64 JPEG carried by the SSE frame with `status:"success"`.

```bash
curl -X POST http://localhost:8080/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-image-1","prompt":"an orange cat in an astronaut suit floating in a starry sky","response_format":"b64_json"}'
```

- `model`: `gpt-image-1` / `gpt-image-2` / `dall-e-3` all alias to `gpt-5.6-luna` (the only free model that can trigger native image generation).
- `response_format`: `b64_json` returns the image bytes directly; the default `url` returns a local link `/v1/images/content/<id>` (in-memory cache, ~50 images).
- `n`: 1–4, generated one by one; `size`: e.g. `1024x1024`, only influences the composition hint (landscape/portrait/square).
- A single generation takes ~25–30 seconds (including warmup and backend render).

```python
from openai import OpenAI
c = OpenAI(base_url="http://localhost:8080/v1", api_key="t")
r = c.images.generate(model="gpt-image-1", prompt="ink-wash style red fox", response_format="b64_json")
open("fox.jpg", "wb").write(__import__("base64").b64decode(r.data[0].b64_json))
```

## 📂 Project layout

- `duckai.py` — Duck.ai transport layer: real Chrome session management, fetch-hook response tee, request-body rewrite (model / reasoningEffort / toolChoice), event-stream parsing (`_parse_event` → `send_ui` / `send_stream_ui` / `send_image_ui`), over-long prompt truncation, ban rotation. Exports `MODEL_LABELS`, `resolve_model`, `DuckAISession`, `fetch_model_catalog`.
- `main.py` — FastAPI app: chat (OpenAI / Anthropic / Responses), images (`/v1/images/generations` + in-memory image cache), the `/v1/models` live catalog, conversation flattening, request logging (`REQ` / `ROUTED` lines).
- `tools.py` — parses `<tool_call …>` XML envelopes in model output (`split_text_and_tool`).
- `toolrouter.py` — experimental intent → `tool_use` synthesis (active only with `DUCKAI_TOOL_ROUTING=1`).
- `start.bat` / `stop.bat` — one-click start/stop on Windows.
- `example.env` — template of every config knob (copy to `.env`).
- `docs/images/` — README screenshots and sample images.

## ⚠️ Known limitations (measured 2026-09-19)

- **~12K-character context cap**: Duck.ai's composer has a hard input limit; the excess is automatically truncated by the relay (keeping the instruction head + the latest question). Not suitable for "understand the whole repo" style heavy agent tasks.
- **Latency**: first cold-start turn ~7–15s (Chrome warmup), follow-ups ~5–10s, image generation ~25–30s. Set client timeout ≥60s.
- **Image generation only triggers on GPT-5.6 Luna** (the only free model with a native `GenerateImage` tool).
- **Ban risk**: Duck.ai issues persistent `ERR_BN_LIMIT` bans per IP/fingerprint for anomalous traffic; the relay auto-rebuilds sessions and rotates proxies, but please keep usage moderate and respect their terms of service.
- Server-side behavior can change anytime (models added/removed, protocol fields adjusted); when something breaks, first check the `REQ` lines in `server.log`, then compare against the live `/v1/models` catalog.

## 📬 Contact

- Email: [wuyouseo@gmail.com](mailto:wuyouseo@gmail.com)
- Telegram: https://t.me/aleiseo

## ⚠️ Disclaimer

Not affiliated with DuckDuckGo. For educational/personal use only; respect Duck.ai's terms of service. Use at your own rate-limit risk.
