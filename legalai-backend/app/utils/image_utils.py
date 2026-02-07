import base64
import io

try:
    from PIL import Image
except Exception:  # pragma: no cover
    Image = None


def image_to_data_url(path: str, max_side: int = 1280) -> str:
    if Image is None:
        raise RuntimeError("Pillow is required for image encoding.")

    with Image.open(path) as raw:
        img = raw.convert("RGB")
        try:
            img = _resize_image(img, max_side)
            buf = io.BytesIO()
            img.save(buf, format="JPEG", quality=85, optimize=True, progressive=True)
            data = base64.b64encode(buf.getvalue()).decode("utf-8")
            return f"data:image/jpeg;base64,{data}"
        finally:
            img.close()


def _resize_image(img, max_side: int):
    if max_side <= 0:
        return img
    w, h = img.size
    if max(w, h) <= max_side:
        return img
    scale = max_side / float(max(w, h))
    new_w = int(w * scale)
    new_h = int(h * scale)
    return img.resize((new_w, new_h), Image.Resampling.LANCZOS)
