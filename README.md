# visual

AI 生成产物集：网页应用、矢量图、3D 模型，通过 GitHub Pages 展示。

## 目录结构

```
html/    AI 生成的单页网页应用（直接发布）
svg/     AI 生成的矢量图（直接发布）
scad/    OpenSCAD 建模源码（CI 转换为 GLB 后在线预览）
manifest.yaml  全站索引：每个条目的标题、提示词、模型、harness 等元数据
tools/build_index.py  站点构建脚本
scad/convert.py       SCAD -> GLB + PNG 缩略图转换脚本
```

## 本地构建与预览

依赖：[uv](https://docs.astral.sh/uv/)、openscad（`brew install openscad`）

```bash
uv run scad/convert.py      # scad -> _site/models/*.glb + 缩略图
uv run tools/build_index.py # 生成 _site/index.html 和模型查看页
cd _site && uv run -m http.server 8000
```

## 收录新产物

1. 把文件放进对应目录（`html/`、`svg/`、`scad/`）
2. 在 `manifest.yaml` 对应分组追加条目（`file`、`title`，以及 `prompt`（多轮提示词列表）、`model`、`effort`、`harness`、`preset` 等元数据）
3. push 即可，GitHub Actions 自动构建并发布到 Pages

构建脚本会校验 manifest 与实际文件的一致性（缺失/未收录会输出警告）。

## 发布

push 到 `main` 触发 `.github/workflows/pages.yml`：安装 openscad →
转换模型 → 构建页面 → 通过 `actions/deploy-pages` 发布。
仓库需在 Settings → Pages 中将 Source 设为 **GitHub Actions**。
