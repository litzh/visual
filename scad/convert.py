# /// script
# requires-python = ">=3.10"
# dependencies = ["trimesh", "scipy"]
# ///
"""SCAD -> GLB 模型 + PNG 缩略图

用法: uv run scad/convert.py [--force]
输入: scad/*.scad（默认取脚本所在目录）
输出: <repo>/_site/models/<name>.glb       模型（three.js GLTFLoader 加载）
      <repo>/_site/assets/thumbs/<name>.png 缩略图（openscad 渲染）
依赖: openscad 需在 PATH 中；trimesh 由 uv 自动安装
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import trimesh

IMGSIZE = "800,600"
COLORSCHEME = "DeepOcean"


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd))
    subprocess.run(cmd, check=True)


def render_png(scad: Path, png: Path) -> None:
    """openscad PNG 渲染需要 OpenGL，headless Linux 下用 xvfb 虚拟显示"""
    cmd = ["openscad", "-o", str(png), f"--imgsize={IMGSIZE}",
           "--viewall", "--autocenter", f"--colorscheme={COLORSCHEME}", str(scad)]
    if (sys.platform.startswith("linux") and not os.environ.get("DISPLAY")
            and shutil.which("xvfb-run")):
        cmd = ["xvfb-run", "-a"] + cmd
    run(cmd)


def newer(path: Path, ref: Path) -> bool:
    """path 存在且比 ref 新"""
    return path.exists() and path.stat().st_mtime >= ref.stat().st_mtime


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?", default=Path(__file__).parent,
                    type=Path, help="scad 文件目录（默认: 脚本所在目录）")
    ap.add_argument("-o", "--out", default=Path(__file__).parent.parent / "_site",
                    type=Path, help="站点输出目录（默认: <repo>/_site）")
    ap.add_argument("--force", action="store_true", help="忽略时间戳，全部重建")
    args = ap.parse_args()

    if not shutil.which("openscad"):
        sys.exit("未找到 openscad，请先安装（macOS: brew install openscad）")

    src_dir = args.src.resolve()
    models_dir = args.out.resolve() / "models"
    thumbs_dir = args.out.resolve() / "assets" / "thumbs"
    models_dir.mkdir(parents=True, exist_ok=True)
    thumbs_dir.mkdir(parents=True, exist_ok=True)

    scad_files = sorted(src_dir.glob("*.scad"))
    if not scad_files:
        sys.exit(f"{src_dir} 下没有 .scad 文件")

    with tempfile.TemporaryDirectory(prefix="scad-stl-") as stl_dir:
        for scad in scad_files:
            name = scad.stem
            stl = Path(stl_dir) / f"{name}.stl"  # 中间产物，用完即删
            glb = models_dir / f"{name}.glb"
            png = thumbs_dir / f"{name}.png"

            if not args.force and newer(glb, scad) and newer(png, scad):
                print(f"跳过 {name}（产物已是最新）")
                continue

            print(f"\n=== {name} ===")
            run(["openscad", "-o", str(stl), str(scad)])

            mesh = trimesh.load(stl)
            # STL 无顶点法线，必须显式包含法线，否则 three.js 光照渲染为黑色
            mesh.export(glb, include_normals=True)
            print(f"  GLB: {glb.stat().st_size / 1024:.0f} KiB, "
                  f"{len(mesh.vertices)} vertices / {len(mesh.faces)} faces")

            render_png(scad, png)

    print(f"\n完成！模型目录: {models_dir}")
    print("接着运行 uv run tools/build_index.py 生成站点页面")


if __name__ == "__main__":
    main()
