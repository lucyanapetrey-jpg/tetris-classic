"""Regenerate Play Store graphics with Block Smile branding.

Matches the visual style of the existing graphics: dark navy gradient background,
colored block grid logo (no Tetris wordmark), white sans-serif headline.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

ROOT = Path(r"D:\tetris_classic")
SCREENS = ROOT / "play_screenshots"

# Background palette taken from existing assets (dark navy slate).
BG_TOP = (35, 47, 65)
BG_BOTTOM = (51, 65, 85)

# Block colors (match existing icon).
COL_YELLOW = (244, 211, 41)
COL_CYAN = (45, 199, 230)
COL_PURPLE = (164, 90, 192)
COL_GREEN = (114, 184, 95)
COL_ORANGE = (235, 145, 38)

# Icon panel background.
ICON_BG_TOP = (15, 18, 38)
ICON_BG_BOTTOM = (28, 32, 58)


def find_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = (
        [
            r"C:\Windows\Fonts\segoeuib.ttf",
            r"C:\Windows\Fonts\arialbd.ttf",
            r"C:\Windows\Fonts\seguisb.ttf",
        ]
        if bold
        else [
            r"C:\Windows\Fonts\segoeui.ttf",
            r"C:\Windows\Fonts\arial.ttf",
        ]
    )
    for p in candidates:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        r = round(top[0] + (bottom[0] - top[0]) * t)
        g = round(top[1] + (bottom[1] - top[1]) * t)
        b = round(top[2] + (bottom[2] - top[2]) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return img


def draw_block(draw, x, y, size, color):
    pad = max(1, size // 30)
    draw.rectangle(
        [x + pad, y + pad, x + size - pad, y + size - pad],
        fill=color,
    )


def draw_icon(canvas: Image.Image, cx: int, cy: int, icon_size: int):
    """Draw the 6x6 colored-block pattern matching the existing logo."""
    panel = Image.new("RGB", (icon_size, icon_size), ICON_BG_TOP)
    pdraw = ImageDraw.Draw(panel)
    # subtle internal gradient
    for y in range(icon_size):
        t = y / icon_size
        r = round(ICON_BG_TOP[0] + (ICON_BG_BOTTOM[0] - ICON_BG_TOP[0]) * t)
        g = round(ICON_BG_TOP[1] + (ICON_BG_BOTTOM[1] - ICON_BG_TOP[1]) * t)
        b = round(ICON_BG_TOP[2] + (ICON_BG_BOTTOM[2] - ICON_BG_TOP[2]) * t)
        pdraw.line([(0, y), (icon_size, y)], fill=(r, g, b))

    cells = 7
    cell = icon_size // cells
    margin = (icon_size - cell * cells) // 2

    # Layout (row,col): generic shapes — NOT the classic Tetris piece set.
    # row 1: yellow pair + cyan quad
    layout = [
        (1, 1, COL_YELLOW), (1, 2, COL_YELLOW),
        (1, 3, COL_CYAN), (1, 4, COL_CYAN), (1, 5, COL_CYAN),
        (2, 1, COL_YELLOW), (2, 2, COL_YELLOW),
        (3, 2, COL_PURPLE), (3, 3, COL_PURPLE), (3, 4, COL_PURPLE),
        (4, 3, COL_PURPLE),
        (5, 1, COL_GREEN), (5, 2, COL_GREEN),
        (5, 4, COL_ORANGE),
        (6, 1, COL_GREEN), (6, 2, COL_GREEN),
        (6, 3, COL_ORANGE), (6, 4, COL_ORANGE), (6, 5, COL_ORANGE),
    ]
    for (row, col, color) in layout:
        x = margin + col * cell
        y = margin + row * cell
        draw_block(pdraw, x, y, cell, color)

    canvas.paste(panel, (cx - icon_size // 2, cy - icon_size // 2))


def text_center(draw, xy, text, font, fill="white"):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text((xy[0] - w // 2, xy[1] - h // 2), text, font=font, fill=fill)


def make_featured():
    W, H = 1024, 500
    img = vertical_gradient((W, H), BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)
    icon_size = 380
    draw_icon(img, 220, H // 2, icon_size)

    title_font = find_font(80, bold=True)
    sub_font = find_font(34)
    draw.text((460, 195), "Block Smile", font=title_font, fill="white")
    draw.text((460, 295), "by Summer Smile", font=sub_font, fill=(200, 210, 225))

    out = ROOT / "play_feature_graphic.png"
    img.save(out, "PNG", optimize=True)
    print(f"wrote {out}")


def make_phone(filename: str, headline: str, footer: str):
    W, H = 1080, 1920
    img = vertical_gradient((W, H), BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    title_font = find_font(96, bold=True)
    foot_font = find_font(44)
    brand_font = find_font(44)

    text_center(draw, (W // 2, 220), headline, title_font, "white")

    icon_size = 760
    draw_icon(img, W // 2, 920, icon_size)

    text_center(draw, (W // 2, 1480), footer, foot_font, (220, 225, 235))
    text_center(draw, (W // 2, 1780), "by Summer Smile", brand_font, (200, 210, 225))

    out = SCREENS / filename
    img.save(out, "PNG", optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    make_featured()
    make_phone("phone_1.png", "Classic Blocks", "Block Smile")
    make_phone("phone_2.png", "Marathon Mode", "Plays offline · No data collection")
    make_phone("phone_3.png", "Combo Bonus", "Plays offline · No data collection")
    make_phone("phone_4.png", "Compete Online", "Plays offline · No data collection")
