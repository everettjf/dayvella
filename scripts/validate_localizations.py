#!/usr/bin/env python3
"""Audit app/widget localization coverage and optionally compiled Xcode resources."""
import argparse
import collections
import json
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {'en', 'zh-Hans', 'ja', 'ko', 'de', 'fr', 'es', 'it', 'pt-BR', 'ru', 'vi'}
FORMAT = re.compile(r'%(?:\d+\$)?(?:lld|@)')
TOKEN = re.compile(r'`([^`]+)`|(?<![A-Za-z0-9_])(sample_import\.json|ISO-8601|IANA|Asia/Shanghai)(?![A-Za-z0-9_])')


def units(node):
    if 'stringUnit' in node:
        yield node['stringUnit']
    for plural in node.get('variations', {}).get('plural', {}).values():
        yield from units(plural)


def rendered_variants(node):
    value = node['stringUnit']['value']
    variants = [value]
    for name, substitution in node.get('substitutions', {}).items():
        replacements = [unit['value'] for unit in units(substitution)]
        variants = [v.replace(f'%#@{name}@', replacement) for v in variants for replacement in replacements]
    return variants


def signature(value):
    return collections.Counter(re.sub(r'^%\d+\$', '%', match) for match in FORMAT.findall(value))


def tokens(value):
    return collections.Counter(a or b for a, b in TOKEN.findall(value))


def audit_catalog(target, errors):
    catalog = json.loads((ROOT / target / 'Localizable.xcstrings').read_text())
    assert catalog['sourceLanguage'] == 'en'
    if target == 'Dayvella':
        palette_names = set(re.findall(r'TrendingCardPalette\(name: "([^"]+)"', (ROOT / 'Dayvella/Utilities/TrendingCardPalettes.swift').read_text()))
        errors.extend(f'{target}: missing dynamic palette key {name}' for name in sorted(palette_names - set(catalog['strings'])))
    for key, entry in catalog['strings'].items():
        if entry.get('shouldTranslate') is False:
            continue
        locales = entry.get('localizations', {})
        if set(locales) != LANGUAGES:
            errors.append(f'{target}: {key}: missing/extra languages {set(locales) ^ LANGUAGES}')
        for language, node in locales.items():
            context = f'{target}/{language}: {key}'
            for unit in list(units(node)) + [u for sub in node.get('substitutions', {}).values() for u in units(sub)]:
                if unit.get('state') != 'translated' or not unit.get('value', '').strip():
                    errors.append(f'{context}: unfinished translation')
            for variant in rendered_variants(node):
                if signature(variant) != signature(key):
                    errors.append(f'{context}: placeholder mismatch: {variant}')
                if tokens(variant) != tokens(key):
                    errors.append(f'{context}: JSON/documentation token mismatch: {variant}')
            for sub in node.get('substitutions', {}).values():
                categories = set(sub['variations']['plural'])
                required = {'one', 'few', 'many', 'other'} if language == 'ru' else ({'other'} if language in {'zh-Hans', 'ja', 'ko', 'vi'} else {'one', 'other'})
                if not required <= categories:
                    errors.append(f'{context}: missing plural categories {required - categories}')
                expected_arg = 3 if key == '%@ %@: %lld days' else 1
                if sub.get('argNum') != expected_arg or sub.get('formatSpecifier') != 'lld':
                    errors.append(f'{context}: invalid count argument')
    return catalog


def audit_build(build_dir, target, catalog, errors):
    extracted = set()
    for path in (build_dir / 'Build/Intermediates.noindex').rglob('*.stringsdata'):
        if path.parent.name != 'arm64' or path.parent.parent.parent.name != f'{target}.build':
            continue
        data = json.loads(path.read_text())
        extracted.update(s['key'] for s in data.get('tables', {}).get('Localizable', []))
    if not extracted:
        errors.append(f'{target}: no compiler extraction evidence')
    missing = extracted - set(catalog['strings'])
    errors.extend(f'{target}: extracted key missing from catalog: {key}' for key in sorted(missing))
    app = build_dir / 'Build/Products/Debug-iphonesimulator/Dayvella.app'
    bundle = app if target == 'Dayvella' else app / 'PlugIns/DayvellaWidget.appex'
    languages = {p.stem for p in bundle.glob('*.lproj')}
    if languages != LANGUAGES:
        errors.append(f'{target}: compiled language mismatch: {languages ^ LANGUAGES}')
    for language in LANGUAGES:
        values = {}
        for filename in ['Localizable.strings', 'Localizable.stringsdict']:
            path = bundle / f'{language}.lproj' / filename
            if path.exists():
                values.update(plistlib.loads(path.read_bytes()))
        for key, entry in catalog['strings'].items():
            if entry.get('shouldTranslate') is False:
                continue
            if key not in values:
                errors.append(f'{target}/{language}: missing compiled key {key}')
            elif 'substitutions' not in entry['localizations'][language] and values[key] != entry['localizations'][language]['stringUnit']['value']:
                errors.append(f'{target}/{language}: stale compiled translation {key}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path)
    args = parser.parse_args()
    errors = []
    reference = ROOT.parent / 'remoboard/remoboard'
    if reference.is_dir():
        remoboard = {p.stem for p in reference.glob('*.lproj') if (p / 'Localizable.strings').exists()}
        if remoboard != LANGUAGES:
            errors.append(f'Remoboard language parity mismatch: {remoboard ^ LANGUAGES}')
    for target in ['Dayvella', 'DayvellaWidget']:
        catalog = audit_catalog(target, errors)
        if args.build_dir:
            audit_build(args.build_dir, target, catalog, errors)
        count = sum(entry.get('shouldTranslate') is not False for entry in catalog['strings'].values())
        print(f'{target}: {count} translated keys × {len(LANGUAGES)} languages')
    if errors:
        raise SystemExit('\n'.join(errors))
    print('Language parity, translations, format arguments, plural rules, and technical tokens passed.' + (' Compiler extraction and compiled resources passed.' if args.build_dir else ''))


if __name__ == '__main__':
    main()
