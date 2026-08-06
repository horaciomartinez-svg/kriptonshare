#!/usr/bin/env python3
"""Verify ARB translation files under lib/l10n."""
import json
from pathlib import Path
from collections import OrderedDict

ROOT = Path(__file__).resolve().parent.parent / "lib" / "l10n"
FILES = {
    "en": ROOT / "app_en.arb",
    "es": ROOT / "app_es.arb",
    "fr": ROOT / "app_fr.arb",
    "de": ROOT / "app_de.arb",
    "pt": ROOT / "app_pt.arb",
}


def load(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def translation_keys(data: dict):
    return {k for k in data if not k.startswith("@") and k != "@@locale"}


def main():
    data = {}
    errors = {}
    counts = {}
    for lang, path in FILES.items():
        try:
            d = load(path)
            data[lang] = d
            counts[lang] = len(translation_keys(d))
        except json.JSONDecodeError as e:
            errors[lang] = str(e)
        except Exception as e:
            errors[lang] = str(e)

    print("=== ARB Verification Report ===\n")
    print("File paths:")
    for lang, path in FILES.items():
        status = "OK" if lang in data else f"ERROR: {errors.get(lang, 'unknown')}"
        print(f"  {path}: {status}")

    print("\nTranslation key counts (excludes @@locale and @metadata keys):")
    for lang in FILES:
        print(f"  {lang}: {counts.get(lang, 'N/A')}")

    if "en" not in data:
        print("\nEnglish file failed to parse; cannot compare.")
        return

    en_keys = translation_keys(data["en"])
    print(f"\nEnglish reference keys: {len(en_keys)}")

    missing_summary = {}
    changed_any = False
    for lang in ["es", "fr", "de", "pt"]:
        if lang not in data:
            continue
        lang_keys = translation_keys(data[lang])
        missing = en_keys - lang_keys
        missing_summary[lang] = missing
        if missing:
            changed_any = True
            print(f"\n{lang}: {len(missing)} missing keys. Adding English fallbacks.")
            for key in sorted(missing):
                value = data["en"][key]
                data[lang][key] = value
                # Also copy metadata key if present in English.
                meta_key = f"@{key}"
                if meta_key in data["en"]:
                    data[lang][meta_key] = data["en"][meta_key]
                print(f"  + {key}")
            # Preserve @@locale at the top.
            locale = data[lang].get("@@locale", lang)
            new_data = OrderedDict()
            new_data["@@locale"] = locale
            for k, v in data[lang].items():
                if k == "@@locale":
                    continue
                new_data[k] = v
            with FILES[lang].open("w", encoding="utf-8") as f:
                json.dump(new_data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        else:
            print(f"\n{lang}: No missing keys.")

    if not changed_any:
        print("\nAll secondary files already contain all English keys.")

    print("\n=== Done ===")


if __name__ == "__main__":
    main()
