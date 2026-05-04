"""
使用参考图片生成 1024x1024 App Icon。
步骤：
1. 将原图缩放到 1024x1024（原图已基本是正方形）
2. 用 iOS 标准圆角矩形 mask 裁切（CORNER_R = 224 at 1024px）
3. 输出 PNG
"""
from PIL import Image, ImageDraw

SRC  = "/Users/xiaoyu.a.sun/.claude/image-cache/215e6c1b-480f-47f9-ab65-e47e949992ce/1.png"
OUT  = "/Users/xiaoyu.a.sun/Documents/git/github/iopanda/PhotixMark/PhotixMark/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
SIZE = 1024
CORNER_R = 224   # iOS 17 superellipse corner radius at 1024px

# ── 1. Load & scale ──────────────────────────────────────
src = Image.open(SRC).convert("RGBA")
src = src.resize((SIZE, SIZE), Image.LANCZOS)

# ── 2. Build rounded-rect mask ───────────────────────────
mask = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    [0, 0, SIZE - 1, SIZE - 1], radius=CORNER_R, fill=255
)

# ── 3. Apply mask ─────────────────────────────────────────
result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
result.paste(src, mask=mask)

# ── 4. Save ───────────────────────────────────────────────
result.save(OUT, "PNG")
print(f"Saved: {OUT}  size={result.size}")
