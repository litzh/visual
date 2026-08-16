# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""读取 manifest.yaml，生成站点页面

用法: uv run tools/build_index.py
输出: <repo>/_site/index.html        卡片式首页（html/svg/scad 三个分区）
      <repo>/_site/models/index.html 3D 模型查看页（下拉切换 + ?model= 深链）
      并拷贝 html/、svg/ 到 _site/ 下
"""

import hashlib
import html as html_mod
import json
import shutil
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).parent.parent
OUT = ROOT / "_site"

STYLE = """
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body {
  margin: 0; padding: 2rem clamp(1rem, 5vw, 4rem);
  background: #0f1226; color: #e8eaf2;
  font: 15px/1.6 -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
}
header { margin-bottom: 2rem; }
h1 { margin: 0 0 .3rem; font-size: 1.8rem; }
.desc { color: #9aa0c3; margin: 0; }
h2 {
  margin: 2.5rem 0 1rem; font-size: 1.2rem; color: #aab2e8;
  border-bottom: 1px solid #2a2f52; padding-bottom: .4rem;
}
.grid {
  display: grid; gap: 1.2rem;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
}
.card {
  background: #1a1e3d; border: 1px solid #2a2f52; border-radius: 12px;
  overflow: hidden; display: flex; flex-direction: column;
  transition: transform .15s, border-color .15s;
}
.card:hover { transform: translateY(-3px); border-color: #5560a8; }
.thumb {
  display: block; aspect-ratio: 4 / 3; position: relative;
  background: #12152e;
}
.thumb img { width: 100%; height: 100%; object-fit: contain; }
.thumb.cover img { object-fit: cover; }
.placeholder {
  width: 100%; height: 100%; display: flex;
  align-items: center; justify-content: center; font-size: 3rem;
}
.body { padding: .9rem 1rem 1rem; display: flex; flex-direction: column; gap: .4rem; }
a.title { color: #e8eaf2; font-weight: 600; text-decoration: none; font-size: 1.05rem; }
a.title:hover { color: #9db4ff; }
.meta { font-size: .8rem; color: #8b91b8; display: flex; flex-wrap: wrap; gap: .3rem .6rem; }
.chip {
  background: #252b52; border-radius: 999px; padding: .05rem .55rem;
  font-size: .75rem; color: #aab2e8;
}
.note { font-size: .8rem; color: #8b91b8; margin: 0; }
details { font-size: .82rem; color: #9aa0c3; }
summary { cursor: pointer; color: #7f8bd4; user-select: none; }
details pre {
  white-space: pre-wrap; word-break: break-word; margin: .5rem 0 0;
  background: #12152e; border-radius: 8px; padding: .6rem .8rem;
  font-size: .8rem; color: #c6cbe8;
}
footer { margin-top: 3rem; color: #5b6188; font-size: .8rem; }
"""

VIEWER_TEMPLATE = """\
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>3D 模型查看器</title>
<style>
  html, body { margin: 0; height: 100%; overflow: hidden; background: #1a1a2e; }
  body { font: 14px/1.5 -apple-system, "PingFang SC", sans-serif; }
  #panel {
    position: fixed; top: 12px; left: 12px; z-index: 10;
    background: rgba(15,18,38,.88); border: 1px solid #2a2f52;
    border-radius: 10px; padding: 10px 14px; color: #e8eaf2;
    max-width: min(420px, 80vw); backdrop-filter: blur(6px);
  }
  #panel .row { display: flex; gap: 8px; align-items: center; }
  select {
    background: #252b52; color: #e8eaf2; border: 1px solid #3a4170;
    border-radius: 6px; padding: 4px 8px; font-size: 14px; max-width: 240px;
  }
  a { color: #8ea2ff; text-decoration: none; }
  #status { color: #9aa0c3; font-size: 12px; margin-top: 6px; }
  #info { margin-top: 6px; font-size: 12px; color: #9aa0c3; display: none; }
  #info summary { cursor: pointer; color: #7f8bd4; }
  #info pre {
    white-space: pre-wrap; word-break: break-word; max-height: 30vh;
    overflow: auto; background: #12152e; border-radius: 6px; padding: 6px 8px;
  }
  .hint { color: #5b6188; font-size: 11px; margin-top: 6px; }
</style>
<script type="importmap">
{
  "imports": {
    "three": "https://unpkg.com/three@0.160.0/build/three.module.js",
    "three/addons/": "https://unpkg.com/three@0.160.0/examples/jsm/"
  }
}
</script>
</head>
<body>
<div id="panel">
  <div class="row">
    <a href="../index.html">← 首页</a>
    <select id="model-select"></select>
  </div>
  <div id="status">初始化…</div>
  <details id="info"><summary>生成信息</summary><div id="info-body"></div></details>
  <div class="hint">拖动旋转 / 滚轮缩放 / 右键平移</div>
</div>
<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const MODELS = __MODELS_JSON__;
const byName = Object.fromEntries(MODELS.map(m => [m.name, m]));

const select = document.getElementById('model-select');
const status = document.getElementById('status');
const infoBox = document.getElementById('info');
const infoBody = document.getElementById('info-body');

for (const m of MODELS) {
  const opt = document.createElement('option');
  opt.value = m.name;
  opt.textContent = m.title || m.name;
  select.appendChild(opt);
}

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1a1a2e);

const camera = new THREE.PerspectiveCamera(50, innerWidth / innerHeight, 0.01, 10000);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);

scene.add(new THREE.HemisphereLight(0xffffff, 0x444444, 1.2));
const dir = new THREE.DirectionalLight(0xffffff, 1.5);
dir.position.set(3, 5, 4);
scene.add(dir);
scene.add(new THREE.GridHelper(10, 20, 0x555555, 0x333333));

const loader = new GLTFLoader();
let current = null;
let loadSeq = 0;

function esc(s) {
  return String(s).replace(/[&<>]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
}

function showInfo(m) {
  const parts = [];
  const prompts = Array.isArray(m.prompt) ? m.prompt : (m.prompt ? [m.prompt] : []);
  if (prompts.length) {
    parts.push('<b>提示词' + (prompts.length > 1 ? '（' + prompts.length + ' 轮）' : '') + '</b>' +
      prompts.map((p, i) => '<pre>' + (i + 1) + '. ' + esc(p) + '</pre>').join(''));
  }
  const chips = [];
  if (m.model) chips.push(m.effort ? m.model + ' · ' + m.effort : m.model);
  if (m.harness) chips.push(m.preset ? m.harness + ' / ' + m.preset : m.harness);
  if (m.date) chips.push(m.date);
  if (m.note) chips.push(m.note);
  if (chips.length) parts.push('<div>' + chips.map(esc).join(' · ') + '</div>');
  infoBody.innerHTML = parts.join('') || '暂无记录';
  infoBox.style.display = 'block';
}

function loadModel(name) {
  const m = byName[name] || MODELS[0];
  select.value = m.name;
  history.replaceState(null, '', '?model=' + encodeURIComponent(m.name));
  document.title = (m.title || m.name) + ' · 3D 模型查看器';
  showInfo(m);
  status.textContent = '加载中…';

  if (current) {
    scene.remove(current);
    current.traverse(c => { if (c.isMesh) { c.geometry.dispose(); c.material.dispose(); } });
    current = null;
  }

  const seq = ++loadSeq;
  loader.load(encodeURIComponent(m.name) + '.glb', (gltf) => {
    if (seq !== loadSeq) return;  // 已切换到其他模型
    const obj = gltf.scene;
    obj.traverse(c => {
      if (!c.isMesh) return;
      if (!c.geometry.attributes.normal) c.geometry.computeVertexNormals();
      c.material = new THREE.MeshStandardMaterial({
        color: 0x88aaff, metalness: 0.1, roughness: 0.6, side: THREE.DoubleSide
      });
    });
    const box = new THREE.Box3().setFromObject(obj);
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3()).length() || 1;
    obj.position.sub(center);
    scene.add(obj);
    current = obj;
    camera.position.set(size, size * 0.7, size);
    // 近平面/远平面随模型尺度调整，避免深度精度不足导致共面闪烁
    camera.near = Math.max(size / 100, 0.001);
    camera.far = size * 20;
    camera.updateProjectionMatrix();
    controls.target.set(0, 0, 0);
    controls.update();
    status.textContent = m.name;
  }, undefined, (err) => {
    if (seq !== loadSeq) return;
    status.textContent = '加载失败: ' + (err.message || err);
  });
}

select.addEventListener('change', () => loadModel(select.value));

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

renderer.setAnimationLoop(() => renderer.render(scene, camera));

const initial = new URLSearchParams(location.search).get('model');
loadModel(initial || MODELS[0].name);
</script>
</body>
</html>
"""


def esc(s) -> str:
    return html_mod.escape(str(s), quote=True)


def hue(name: str) -> int:
    return int(hashlib.md5(name.encode()).hexdigest()[:4], 16) % 360


def placeholder(name: str, emoji: str) -> str:
    h = hue(name)
    bg = f"linear-gradient(135deg, hsl({h},55%,38%), hsl({(h + 60) % 360},55%,22%))"
    return f'<div class="placeholder" style="background:{bg}">{emoji}</div>'


def prompts_of(e: dict) -> list[str]:
    """prompt 兼容字符串与列表两种写法，统一返回列表"""
    p = e.get("prompt")
    if not p:
        return []
    items = p if isinstance(p, list) else [p]
    return [str(x).strip() for x in items if str(x).strip()]


def meta_html(e: dict) -> str:
    chips = []
    if e.get("model"):
        m = esc(e["model"])
        if e.get("effort"):
            m += f" · {esc(e['effort'])}"
        chips.append(f'<span class="chip">{m}</span>')
    if e.get("harness"):
        h = esc(e["harness"])
        if e.get("preset"):
            h += f" / {esc(e['preset'])}"
        chips.append(f'<span class="chip">{h}</span>')
    if e.get("date"):
        chips.append(f'<span class="chip">{esc(e["date"])}</span>')
    return f'<div class="meta">{"".join(chips)}</div>' if chips else ""


def prompt_html(e: dict) -> str:
    prompts = prompts_of(e)
    if not prompts:
        return ""
    pres = "".join(f"<pre>{i + 1}. {esc(p)}</pre>" for i, p in enumerate(prompts))
    label = f"生成提示词（{len(prompts)} 轮）" if len(prompts) > 1 else "生成提示词"
    return f"<details><summary>{label}</summary>{pres}</details>"


def card(e: dict, href: str, thumb: str, extra: str = "") -> str:
    note = e.get("note")
    note_html = f'<p class="note">{esc(note)}</p>' if note else ""
    return f"""<div class="card">
  <a class="thumb{extra}" href="{href}" target="_blank">{thumb}</a>
  <div class="body">
    <a class="title" href="{href}" target="_blank">{esc(e.get("title") or e["file"])}</a>
    {meta_html(e)}
    {note_html}
    {prompt_html(e)}
  </div>
</div>"""


def check_entries(section: str, entries: list[dict], base: Path,
                  suffix: str) -> None:
    listed = {e["file"] for e in entries}
    for e in entries:
        if not (base / e["file"]).exists():
            print(f"警告: manifest[{section}] 中的 {e['file']} 不存在", file=sys.stderr)
    for f in sorted(base.glob(f"*{suffix}")):
        if f.name not in listed:
            print(f"警告: {f.relative_to(ROOT)} 未收录进 manifest[{section}]",
                  file=sys.stderr)


def main() -> None:
    manifest = yaml.safe_load((ROOT / "manifest.yaml").read_text(encoding="utf-8"))
    html_entries = manifest.get("html") or []
    svg_entries = manifest.get("svg") or []
    scad_entries = manifest.get("scad") or []

    # 一致性检查
    check_entries("html", html_entries, ROOT / "html", ".html")
    check_entries("svg", svg_entries, ROOT / "svg", ".svg")
    check_entries("scad", scad_entries, ROOT / "scad", ".scad")

    # 拷贝静态目录
    for d in ("html", "svg"):
        if (ROOT / d).is_dir():
            shutil.copytree(ROOT / d, OUT / d, dirs_exist_ok=True)
    (OUT / "models").mkdir(parents=True, exist_ok=True)

    # ---- 首页 ----
    sections = []

    if html_entries:
        cards = "".join(
            card(e, f"html/{e['file']}", placeholder(e["file"], "✨"))
            for e in html_entries
        )
        sections.append(f"<h2>网页应用（{len(html_entries)}）</h2>"
                        f'<div class="grid">{cards}</div>')

    if svg_entries:
        cards = "".join(
            card(e, f"svg/{e['file']}",
                 f'<img src="svg/{e["file"]}" alt="{esc(e.get("title") or e["file"])}" loading="lazy">')
            for e in svg_entries
        )
        sections.append(f"<h2>矢量图（{len(svg_entries)}）</h2>"
                        f'<div class="grid">{cards}</div>')

    if scad_entries:
        cards = []
        for e in scad_entries:
            stem = Path(e["file"]).stem
            thumb_path = OUT / "assets" / "thumbs" / f"{stem}.png"
            if not (OUT / "models" / f"{stem}.glb").exists():
                print(f"提示: models/{stem}.glb 尚未生成，先运行 "
                      f"uv run scad/convert.py", file=sys.stderr)
            if thumb_path.exists():
                thumb = (f'<img src="assets/thumbs/{stem}.png" '
                         f'alt="{esc(e.get("title") or stem)}" loading="lazy">')
                cards.append(card(e, f"models/?model={stem}", thumb, " cover"))
            else:
                cards.append(card(e, f"models/?model={stem}",
                                  placeholder(stem, "🧊")))
        sections.append(f"<h2>3D 模型（{len(scad_entries)}）</h2>"
                        f'<div class="grid">{"".join(cards)}</div>')

    page = f"""<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(manifest.get("title") or "作品集")}</title>
<style>{STYLE}</style>
</head>
<body>
<header>
  <h1>{esc(manifest.get("title") or "作品集")}</h1>
  <p class="desc">{esc(manifest.get("description") or "")}</p>
</header>
{"".join(sections)}
<footer>由 AI 生成 · <a href="https://github.com" style="color:#7f8bd4">GitHub Pages</a> 托管</footer>
</body>
</html>
"""
    (OUT / "index.html").write_text(page, encoding="utf-8")

    # ---- 模型查看页 ----
    if scad_entries:
        models = [
            {
                "name": Path(e["file"]).stem,
                "title": e.get("title") or "",
                "prompt": prompts_of(e),
                "model": e.get("model") or "",
                "effort": e.get("effort") or "",
                "harness": e.get("harness") or "",
                "preset": e.get("preset") or "",
                "date": str(e.get("date") or ""),
                "note": e.get("note") or "",
            }
            for e in scad_entries
        ]
        models_json = json.dumps(models, ensure_ascii=False).replace("</", "<\\/")
        viewer = VIEWER_TEMPLATE.replace("__MODELS_JSON__", models_json)
        (OUT / "models" / "index.html").write_text(viewer, encoding="utf-8")

    print(f"完成！站点目录: {OUT}")
    print(f"本地预览: cd {OUT} && uv run -m http.server 8000")


if __name__ == "__main__":
    main()
