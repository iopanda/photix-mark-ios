"""
PhotixMark app icon (1024x1024).

Layout (top → bottom):
  ┌──────────────────────────────────┐
  │                                  │  ← white photo area (~56%)
  ├──────────────────────────────────┤  ← divider
  │  [Leica circle logo]  model text │  ← brand row (~22%)
  ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┤  ← thin separator
  │  f/1.4  │ 1/500 │ ISO 200│ 50mm │  ← EXIF row (~22%)
  └──────────────────────────────────┘
"""
import cairosvg
from PIL import Image, ImageDraw, ImageFont
import io

SIZE = 1024
OUT  = "/Users/xiaoyu.a.sun/Documents/git/github/iopanda/PhotixMark/PhotixMark/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
SVG  = "/Users/xiaoyu.a.sun/Documents/git/github/iopanda/PhotixMark/temp/leica_logo.svg"
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"

# ── Palette ──────────────────────────────────────────────
WHITE      = (255, 255, 255, 255)
BAR_BG     = (243, 241, 238, 255)
NEAR_BLACK = (18,  18,  18,  255)
MID_GRAY   = (148, 146, 143, 255)
DIVIDER    = (205, 201, 196, 255)

# ── Zone boundaries ──────────────────────────────────────
CORNER_R  = 224          # iOS 17 superellipse at 1024px

PHOTO_BOT = int(SIZE * 0.56)          # white photo area ends here
BAR_TOP   = PHOTO_BOT
BAR_BOT   = SIZE

BRAND_TOP = BAR_TOP
BRAND_BOT = BAR_TOP + int((BAR_BOT - BAR_TOP) * 0.52)
EXIF_TOP  = BRAND_BOT
EXIF_BOT  = BAR_BOT

# Horizontal safe zone (clear of corner-radius clip at bottom corners)
# At y = SIZE, the iOS squircle clips ~CORNER_R px from each side.
# We add generous left/right padding so nothing is clipped.
PAD_X = 100


# ── Helpers ──────────────────────────────────────────────
def load_font(size, bold=False):
    try:
        return ImageFont.truetype(FONT, size, index=1 if bold else 0)
    except Exception:
        return ImageFont.truetype(FONT, size)


def text_w(draw, text, font):
    bb = draw.textbbox((0, 0), text, font=font)
    return bb[2] - bb[0]


def text_h(draw, text, font):
    bb = draw.textbbox((0, 0), text, font=font)
    return bb[3] - bb[1]


def draw_centered(draw, cx, y, text, font, fill):
    w = text_w(draw, text, font)
    draw.text((cx - w // 2, y), text, font=font, fill=fill)


def make_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255
    )
    return m


# ── Build canvas ─────────────────────────────────────────
img  = Image.new("RGBA", (SIZE, SIZE), WHITE)
draw = ImageDraw.Draw(img)

# Photo area: pure white (already the canvas default)

# Divider
draw.line([(0, PHOTO_BOT), (SIZE, PHOTO_BOT)], fill=DIVIDER, width=3)

# Bar background
draw.rectangle([0, BAR_TOP, SIZE, SIZE], fill=BAR_BG)

# Thin separator between brand row and EXIF row
draw.line(
    [(PAD_X, EXIF_TOP), (SIZE - PAD_X, EXIF_TOP)],
    fill=DIVIDER, width=2
)

# ── Leica SVG logo ────────────────────────────────────────
LOGO_SIZE = 148   # diameter of Leica circle in pixels
logo_png = cairosvg.svg2png(
    url=SVG, output_width=LOGO_SIZE, output_height=LOGO_SIZE
)
logo = Image.open(io.BytesIO(logo_png)).convert("RGBA")

BRAND_H  = BRAND_BOT - BRAND_TOP
logo_y   = BRAND_TOP + (BRAND_H - LOGO_SIZE) // 2
logo_x   = PAD_X
img.paste(logo, (logo_x, logo_y), logo)

# ── Brand text (right of logo) ────────────────────────────
TEXT_X    = logo_x + LOGO_SIZE + 28
brand_cx  = (TEXT_X + SIZE - PAD_X) // 2   # centre of remaining width

font_model = load_font(56)

model_text = "M11  ·  Summilux-M 50 f/1.4"
mh = text_h(draw, model_text, font_model)

# Vertically centre model text in brand row
model_y = BRAND_TOP + (BRAND_H - mh) // 2
draw.text((TEXT_X, model_y), model_text, font=font_model, fill=MID_GRAY)

# ── EXIF grid ─────────────────────────────────────────────
exif_items = ["f/1.4", "1/500s", "ISO 200", "50mm"]

font_val = load_font(54, bold=True)

EXIF_H = EXIF_BOT - EXIF_TOP
grid_w = SIZE - PAD_X * 2
cell_w = grid_w // len(exif_items)

# Vertically centre values in EXIF zone
sample_vh = text_h(draw, "f/1.4", font_val)
block_top = EXIF_TOP + (EXIF_H - sample_vh) // 2

for i, val in enumerate(exif_items):
    cx = PAD_X + i * cell_w + cell_w // 2

    # Vertical separator
    if i > 0:
        sx = PAD_X + i * cell_w
        draw.line(
            [(sx, EXIF_TOP + 16), (sx, EXIF_BOT - 16)],
            fill=DIVIDER, width=2
        )

    # Auto-shrink font if value is too wide for cell
    f = font_val
    while text_w(draw, val, f) > cell_w - 16 and f.size > 20:
        f = load_font(f.size - 4, bold=True)

    vw = text_w(draw, val, f)
    vh = text_h(draw, val, f)
    draw.text((cx - vw // 2, block_top + (sample_vh - vh) // 2), val, font=f, fill=NEAR_BLACK)

# ── Rounded-rect mask ─────────────────────────────────────
mask   = make_mask((SIZE, SIZE), CORNER_R)
result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
result.paste(img, mask=mask)

result.save(OUT, "PNG")
print(f"Saved: {OUT}")
