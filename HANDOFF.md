# HANDOFF — paranoid-tools

Точка передачи между машинами (work Mac Mini → home Air). При «Продолжаем работу»
читать этот файл первым: умбрелла-папка, root-PROGRESS.md нет, состояние — по репо.

## Снимок на закрытие сессии (2026-06-19)

| Репо | HEAD | Тег | Тесты | Состояние |
|------|------|-----|-------|-----------|
| `paranoid-tools` (umbrella) | `85e5b04` | — | — | pushed ✓ |
| `ghostdraft` | `cd9937e` | **v0.1.0** ✓ | bats 21/21 | released, CI green, pushed ✓ |
| `seedsplit` | `b3e14b0` | — | bats 9/9 | **scaffold закоммичен ЛОКАЛЬНО, НЕ запушен** ⚠ |
| securetrash | — | v0.4.0 | — | released |
| vaultwatch | — | v0.1.0 | — | released |
| panic | — | v0.1.0 | — | released |

Экосистема: **4/5 released** (securetrash, vaultwatch, panic, ghostdraft).

## Что сделано в этой сессии

1. **ghostdraft pack 2** — `pipe` + `new` (vault→RAM-disk→honest refuse, shred,
   editor-cleanup) + `--clipboard`. Поймали real RAM-disk leak (subshell-глобал →
   несём dev-node через stdout) + 3 Linux-CI бага (uname-стаб, portable `stat`, SC2015).
2. **ghostdraft pack 3** — release-паритет: `install.sh` + `release.yml` + `CHANGELOG.md`,
   тег `v0.1.0` → Release с verified-ассетами (`SHA256SUMS` сошёлся, бинарь даёт 0.1.0).
3. **seedsplit pack 1 (scaffold)** — НЕЗАВЕРШЁН по push (см. ниже).

## ⚠ ГЛАВНОЕ незакрытое — seedsplit push

- Локальный коммит `b3e14b0` есть (scaffold: vendored common + dispatcher skeleton,
  `split`/`combine` deferred exit 2, bats 9/9, shellcheck clean). Working tree чистый.
- Remote `Di-kairos/seedsplit` **создан** (private), но **пустой** — push отклонён:
  токен на этой машине без `workflow`-scope (`gist, read:org, repo`), а коммит содержит
  `.github/workflows/ci.yml`.
- X10 несёт локальный `.git` → коммит восстановим на домашней машине напрямую.

### Доделать на домашней машине (по шагам)

```bash
cd "/Volumes/X10 Pro/projects/paranoid-tools/seedsplit"
gh auth status            # есть ли workflow-scope на домашнем токене?
# если нет:
gh auth refresh -s workflow   # интерактивно (браузер/device-code) — запустить как ! команду
git push -u origin main       # зальёт scaffold + ci.yml; CI должен стать green
```

Если домашний токен тоже без workflow-scope и refresh нежелателен — fallback:
`git rm --cached .github/workflows/ci.yml && git commit --amend` (убрать workflow из
коммита), `git push -u origin main`, затем добавить `ci.yml` отдельным коммитом позже.

После push:
- обновить umbrella `README.md`: seedsplit `🚧 scaffold` → подтвердить (уже помечено
  scaffold в этой сессии, см. строку таблицы «Состав»);
- проверить CI: `gh run list --repo Di-kairos/seedsplit --limit 1`.

## Следующие паки (бэклог)

- **seedsplit pack 2** — ядро Shamir над GF(256) на чистом Bash: `split` (N долей, порог T),
  `combine`. ГСЧ `/dev/urandom`. Секрет через stdin/файл (не argv — виден в `ps`).
  Решение по объёму: SLIP-39-совместимость (1024-словарь + RS1024 + шифрование) —
  отдельно, НЕ «ноль зависимостей»; в scaffold честно помечено как scope-вопрос.
- graphify-out у ghostdraft/panic/seedsplit (нет) → богаче merged cross-repo граф (§15).
- ECOSYSTEM §7: единый `check`-движок, единый бренд вывода.
- мелочь: у securetrash нет `CHANGELOG.md` (паритет-гэп).

## Vendoring pin (общий)

Все тулы вендорят `securetrash/lib/common.sh` pin `2e3d2dd` (SHA256
`fdfb0e3c…af75`). `tools/vendor-common.sh --check` ловит дрейф в CI.
