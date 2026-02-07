import os
from typing import List

from flask import current_app

try:
    import fitz  # PyMuPDF
except Exception:  # pragma: no cover
    fitz = None

try:
    from PIL import Image
except Exception:  # pragma: no cover
    Image = None


def render_source_pages(source_id: int, source_type: str, source_path: str) -> List[dict]:
    """
    Render PDF pages or normalize images into page PNGs.
    Returns list of page dicts with {page_number, path, width, height}.
    """
    pages: List[dict] = []
    if not source_path:
        return pages

    base = current_app.config["STORAGE_BASE"]
    out_dir = os.path.join(base, "knowledge_pages", f"source_{source_id}")
    os.makedirs(out_dir, exist_ok=True)

    max_pages = int(current_app.config.get("MAX_PAGES_PER_DOC", 80))
    max_side = int(current_app.config.get("MAX_PAGE_IMAGE_SIDE", 1600))
    dpi = int(current_app.config.get("PDF_RENDER_DPI", 150))

    if source_type == "pdf":
        if fitz is None:
            current_app.logger.warning("PyMuPDF missing; skipping PDF page rendering.")
            return pages

        with fitz.open(source_path) as doc:
            for i, page in enumerate(doc):
                if i >= max_pages:
                    break
                mat = fitz.Matrix(dpi / 72.0, dpi / 72.0)
                pix = page.get_pixmap(matrix=mat, alpha=False)
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                try:
                    img = _resize_image(img, max_side)
                    out_path = os.path.join(out_dir, f"page_{i + 1}.png")
                    img.save(out_path, format="PNG", optimize=True)
                    pages.append({
                        "page_number": i + 1,
                        "path": out_path,
                        "width": img.width,
                        "height": img.height,
                    })
                finally:
                    img.close()
        return pages

    if source_type in {"png", "jpg", "jpeg"}:
        if Image is None:
            current_app.logger.warning("Pillow missing; skipping image rendering.")
            return pages
        with Image.open(source_path) as raw:
            img = raw.convert("RGB")
            try:
                img = _resize_image(img, max_side)
                out_path = os.path.join(out_dir, "page_1.png")
                img.save(out_path, format="PNG", optimize=True)
                pages.append({
                    "page_number": 1,
                    "path": out_path,
                    "width": img.width,
                    "height": img.height,
                })
            finally:
                img.close()

    return pages


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
