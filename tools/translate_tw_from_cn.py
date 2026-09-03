#!/usr/bin/env python3
"""
Batch translate FreeCAD zh-TW .ts files using zh-CN translations as a base,
converting Simplified Chinese to Traditional Chinese via OpenCC.
"""
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    import opencc
    CONVERTER = opencc.OpenCC('s2twp')  # Simplified to Traditional (Taiwan with phrases)
except ImportError:
    try:
        import opencc_python_reimplemented as opencc
        CONVERTER = opencc.OpenCC('s2tw')
    except ImportError:
        raise RuntimeError("OpenCC not available")


def get_cn_path(tw_path: Path) -> Path:
    """Derive the zh-CN path from a zh-TW path."""
    return Path(str(tw_path).replace('_zh-TW.ts', '_zh-CN.ts'))


def parse_ts(filepath: Path) -> ET.ElementTree:
    """Parse a .ts file, preserving the XML declaration and doctype."""
    tree = ET.parse(filepath)
    return tree


def build_source_map(root: ET.Element) -> dict:
    """Build a map of source text -> translation text from a TS file."""
    source_map = {}
    for context in root.findall('context'):
        for message in context.findall('message'):
            source_elem = message.find('source')
            trans_elem = message.find('translation')
            if source_elem is not None and trans_elem is not None:
                source_text = source_elem.text or ''
                trans_text = trans_elem.text or ''
                # Only map if translation is not empty and not unfinished
                if trans_text and trans_elem.get('type') != 'unfinished':
                    source_map[source_text] = trans_text
    return source_map


def process_tw_file(tw_path: Path, cn_path: Path) -> int:
    """Process a single zh-TW file, filling in unfinished translations from zh-CN."""
    if not cn_path.exists():
        print(f"  [SKIP] No zh-CN file found: {cn_path.name}")
        return 0

    tw_tree = parse_ts(tw_path)
    tw_root = tw_tree.getroot()

    cn_tree = parse_ts(cn_path)
    cn_root = cn_tree.getroot()
    cn_map = build_source_map(cn_root)

    updated = 0
    for context in tw_root.findall('context'):
        for message in context.findall('message'):
            trans_elem = message.find('translation')
            if trans_elem is not None and trans_elem.get('type') == 'unfinished':
                source_elem = message.find('source')
                source_text = source_elem.text if source_elem is not None else ''

                if source_text in cn_map:
                    cn_text = cn_map[source_text]
                    tw_text = CONVERTER.convert(cn_text)
                    trans_elem.text = tw_text
                    del trans_elem.attrib['type']
                    updated += 1

    if updated > 0:
        # Preserve XML declaration and doctype manually by reading the first lines
        with open(tw_path, 'r', encoding='utf-8') as f:
            original_lines = f.readlines()

        # Find XML declaration and DOCTYPE
        header_lines = []
        for line in original_lines:
            stripped = line.strip()
            if stripped.startswith('<?xml') or stripped.startswith('<!DOCTYPE'):
                header_lines.append(line)
            else:
                break

        # Write back
        tw_tree.write(tw_path, encoding='utf-8', xml_declaration=False)

        with open(tw_path, 'r', encoding='utf-8') as f:
            content = f.read()

        with open(tw_path, 'w', encoding='utf-8') as f:
            for hl in header_lines:
                f.write(hl)
            f.write(content)

        print(f"  [UPDATED] {tw_path.name}: {updated} translations filled")
    else:
        print(f"  [OK] {tw_path.name}: no unfinished translations to fill")

    return updated


def main():
    base_dir = Path(__file__).resolve().parent.parent  # 專案根目錄
    tw_files = list(base_dir.rglob('*_zh-TW.ts'))

    total_updated = 0
    print(f"Found {len(tw_files)} zh-TW translation files.")
    print("=" * 60)

    for tw_path in sorted(tw_files):
        cn_path = get_cn_path(tw_path)
        total_updated += process_tw_file(tw_path, cn_path)

    print("=" * 60)
    print(f"Total translations filled: {total_updated}")


if __name__ == '__main__':
    main()
