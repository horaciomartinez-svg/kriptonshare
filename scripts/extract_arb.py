import re
import json
import os

with open('KRIPTONSHARE_Plan_Arquitectura_i18n_l10n_v2.md', 'r', encoding='utf-8') as f:
    content = f.read()

sections = [
    ('app_en.arb', r'### 5\.2 `lib/l10n/app_en\.arb`.*?```json\n(.*?)```\n', 'lib/l10n/app_en.arb'),
    ('app_es.arb', r'### 5\.3 `lib/l10n/app_es\.arb`.*?```json\n(.*?)```\n', 'lib/l10n/app_es.arb'),
    ('app_fr.arb', r'### 5\.4 `lib/l10n/app_fr\.arb`.*?```json\n(.*?)```\n', 'lib/l10n/app_fr.arb'),
    ('app_de.arb', r'### 5\.5 `lib/l10n/app_de\.arb`.*?```json\n(.*?)```\n', 'lib/l10n/app_de.arb'),
    ('app_pt.arb', r'### 5\.6 `lib/l10n/app_pt\.arb`.*?```json\n(.*?)```\n', 'lib/l10n/app_pt.arb'),
]

required_keys = [
    'profileTitle', 'analyticsTitle', 'storageManagementTitle',
    'errorUserNotAuthenticated', 'viewsCount', 'activeTag', 'expiredTag',
    'expiresOn', 'remainingLinks', 'freePlanLabel', 'dataRoomExplorerTitle',
    'eventLobbyEnter'
]

english = None

for name, pattern, out_path in sections:
    m = re.search(pattern, content, re.DOTALL)
    if not m:
        print(f'FAIL extraction: {name}')
        continue
    block = m.group(1).rstrip() + '\n'
    data = json.loads(block)

    # Ensure @@locale present and correct
    locale = name.split('_')[1].split('.')[0]
    data['@@locale'] = locale

    if name == 'app_en.arb':
        english = data

    # Add missing required keys from English fallback
    if english and data is not english:
        for key in required_keys:
            if key not in data:
                data[key] = english[key]
                print(f'  Added fallback {key} to {name}')

    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    # Count top-level string keys only
    string_keys = [k for k in data.keys() if isinstance(data[k], str)]
    print(f'Wrote {out_path}: {len(string_keys)} top-level string keys')
