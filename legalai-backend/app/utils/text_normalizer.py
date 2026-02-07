import re

_HEADER_LINE_RE = re.compile(
    r'^(step|issue|category|section|clause|rule|article|part|item)\s*[:\-–]?\s*$',
    re.IGNORECASE,
)
_NUMBER_LINE_RE = re.compile(r'^\s*\$?(\d{1,2})\s*[.)-]?\s*$')


def _merge_header_number_lines(lines: list[str]) -> list[str]:
    merged = []
    i = 0
    while i < len(lines):
        line = lines[i]
        trimmed = line.strip()
        header_match = _HEADER_LINE_RE.match(trimmed)
        if header_match and i + 1 < len(lines):
            next_trimmed = lines[i + 1].strip()
            num_match = _NUMBER_LINE_RE.match(next_trimmed)
            if num_match:
                label = header_match.group(1) or trimmed
                merged.append(f"{label.title()} {num_match.group(1)}")
                i += 2
                continue
        if _NUMBER_LINE_RE.match(trimmed):
            i += 1
            continue
        merged.append(line)
        i += 1
    return merged


def _normalize_section_markers(text: str) -> str:
    out = text
    out = re.sub(r'(^|\n)\s*\$(\d+)\b', r'\1Section \2', out)
    out = re.sub(r'\b(section|sec\.?|s\.?)\s*\$(\d+)\b', r'Section \2', out, flags=re.IGNORECASE)
    return out


def normalize_rag_context(text: str) -> str:
    if not text:
        return text
    cleaned = text.replace("\r\n", "\n")
    lines = cleaned.split("\n")
    lines = _merge_header_number_lines(lines)
    cleaned = "\n".join(lines)
    cleaned = _normalize_section_markers(cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()


def normalize_llm_answer(text: str) -> str:
    if not text:
        return text
    cleaned = text.replace("\r\n", "\n")
    lines = cleaned.split("\n")
    lines = _merge_header_number_lines(lines)
    cleaned = "\n".join(lines)
    cleaned = _normalize_section_markers(cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()
