import sys
from PIL import Image
# usage: metric.py png x0 y0 x1 y1
p = sys.argv[1]
box = tuple(int(v) for v in sys.argv[2:6])
im = Image.open(p).convert("RGB").crop(box)
px = list(im.getdata())
n = len(px)
black = sum(1 for r, g, b in px if max(r, g, b) <= 6)
lum = sum(0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b in px) / n
q = len(set((r >> 4, g >> 4, b >> 4) for r, g, b in im.resize((96, 60)).getdata()))
print(f"black={black / n:.3f} lum={lum:.1f} colors={q}")
