#!/usr/bin/env python3
"""Generates every J'ealth launcher / favicon / splash raster from one design.

The geometry below mirrors lib/core/widgets/jealth_logo.dart (unit square
coordinates), so the in-app vector logo and the platform icons stay identical.

Usage (from the jealth/ directory):  python3 tool/generate_icons.py
Requires: Pillow.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BLUE = (0x14, 0x6C, 0x94)
TEAL = (0x16, 0xA6, 0xA1)
OFF_WHITE = (0xF5, 0xF8, 0xFC)
WHITE = (255, 255, 255)
SS = 4  # supersampling factor

# Heart outline: closed chain of cubic Beziers in unit coordinates.
HEART = [
    ((0.500, 0.335), (0.500, 0.262), (0.436, 0.205), (0.352, 0.205)),
    ((0.352, 0.205), (0.250, 0.205), (0.180, 0.287), (0.180, 0.392)),
    ((0.180, 0.392), (0.180, 0.560), (0.345, 0.672), (0.500, 0.812)),
    ((0.500, 0.812), (0.655, 0.672), (0.820, 0.560), (0.820, 0.392)),
    ((0.820, 0.392), (0.820, 0.287), (0.750, 0.205), (0.648, 0.205)),
    ((0.648, 0.205), (0.564, 0.205), (0.500, 0.262), (0.500, 0.335)),
]
# ECG pulse polyline drawn across the heart.
PULSE = [(0.255, 0.470), (0.385, 0.470), (0.435, 0.365), (0.505, 0.610),
         (0.570, 0.400), (0.610, 0.470), (0.745, 0.470)]
PULSE_WIDTH = 0.042
CORNER_RADIUS = 0.225


def bezier(p0, p1, p2, p3, steps=48):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def gradient(size):
    """Diagonal blue -> teal gradient (top-left to bottom-right)."""
    small = Image.new("RGB", (64, 64))
    px = small.load()
    for y in range(64):
        for x in range(64):
            t = (x + y) / 126
            px[x, y] = tuple(round(BLUE[i] + (TEAL[i] - BLUE[i]) * t) for i in range(3))
    return small.resize((size, size), Image.BILINEAR)


def mark_layer(size, scale=1.0, heart_fill=WHITE, pulse_fill=BLUE):
    """Transparent layer with the heart + pulse, scaled around the centre."""
    s = size * SS
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def tx(p):
        return ((0.5 + (p[0] - 0.5) * scale) * s, (0.5 + (p[1] - 0.5) * scale) * s)

    heart = []
    for seg in HEART:
        heart += [tx(p) for p in bezier(*seg)]
    d.polygon(heart, fill=heart_fill + (255,))
    w = max(1, round(PULSE_WIDTH * scale * s))
    pts = [tx(p) for p in PULSE]
    d.line(pts, fill=pulse_fill + (255,), width=w, joint="curve")
    r = w / 2
    for (x, y) in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=pulse_fill + (255,))
    return layer.resize((size, size), Image.LANCZOS)


def icon(size, rounded=True, mark_scale=1.0, opaque=False):
    """Full icon: gradient tile + white heart + blue pulse."""
    base = gradient(size).convert("RGBA")
    base.alpha_composite(mark_layer(size, mark_scale))
    if rounded:
        s = size * SS
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, s - 1, s - 1), radius=CORNER_RADIUS * s, fill=255)
        base.putalpha(mask.resize((size, size), Image.LANCZOS))
    return base.convert("RGB") if opaque else base


def save(img, rel):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", rel)


def main():
    # Master artwork (documentation / store listing).
    save(icon(1024), "assets/icons/jealth_icon.png")

    # Android: legacy launcher icons + adaptive foreground + launch logo.
    for name, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(icon(px), f"android/app/src/main/res/mipmap-{name}/ic_launcher.png")
    for name, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        # Adaptive icons keep the artwork inside the central 66% safe zone.
        save(mark_layer(px, 0.62), f"android/app/src/main/res/drawable-{name}/ic_launcher_foreground.png")
    for name, px in {"mdpi": 96, "hdpi": 144, "xhdpi": 192, "xxhdpi": 288, "xxxhdpi": 384}.items():
        save(icon(px), f"android/app/src/main/res/drawable-{name}/launch_logo.png")

    # iOS: opaque, square (the OS applies its own mask).
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for f in sorted(ios.glob("*.png")):
        px = Image.open(f).size[0]
        save(icon(px, rounded=False, opaque=True), f.relative_to(ROOT))
    launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, px in {"LaunchImage.png": 120, "LaunchImage@2x.png": 240, "LaunchImage@3x.png": 360}.items():
        save(icon(px), (launch / name).relative_to(ROOT))

    # Web: favicon, PWA icons and maskable variants (full-bleed, smaller mark).
    save(icon(64), "web/favicon.png")
    save(icon(192), "web/icons/Icon-192.png")
    save(icon(512), "web/icons/Icon-512.png")
    save(icon(192, rounded=False, mark_scale=0.78, opaque=True), "web/icons/Icon-maskable-192.png")
    save(icon(512, rounded=False, mark_scale=0.78, opaque=True), "web/icons/Icon-maskable-512.png")

    # Windows: multi-resolution .ico.
    ico = ROOT / "windows/runner/resources/app_icon.ico"
    icon(256).save(ico, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("wrote", ico.relative_to(ROOT))


if __name__ == "__main__":
    main()
