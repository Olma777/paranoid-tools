# HANDOFF — paranoid-tools

Точка передачи между машинами. При «Продолжаем работу» читать первым: умбрелла-папка,
root-PROGRESS.md нет, состояние — по репо.

## Снимок (2026-06-20, сессия 3 — max polish)

| Репо | HEAD | Тег/Release | Тесты | Публикационная готовность |
|------|------|------|-------|-----------|
| `paranoid-tools` (umbrella) | pushed ✓ | — | — | EN README + README.ru + LICENSE ✓ |
| `securetrash` | `42f8129` | v0.4.0 ✓ | bats 59/59 | эталон — полная обвязка ✓ |
| `vaultwatch` | `e33c962` | v0.1.0 ✓ | bats 50/50 | полная обвязка ✓ |
| `panic` | `46fe075` | v0.1.0 ✓ | bats 24/24 | полная обвязка ✓ |
| `ghostdraft` | `1347a1a` | v0.1.0 ✓ | bats 25/25 | полная обвязка ✓ |
| `seedsplit` | `cf5a1a4` | v0.2.0 ✓ (release вручную) | bats 31/31 | полная обвязка ✓ (CI отложен) |

**Итог: bats 189/189 зелёных, shellcheck clean ×5, vendor sync.** Все 5 репо приведены
к публикационному качеству (кроме двух gated-пунктов ниже).

## Что сделано в сессии 3 (max polish)

Аудит 6 репо (workflow) → punch-list → паки (каждый — параллельный workflow):
- **Pack A:** `-v/--version` + `-h/--help` флаги + bats-тесты во всех 5 тулах.
- **Pack B:** LICENSE + SECURITY.md + CONTRIBUTING.md в vaultwatch/panic/ghostdraft/seedsplit
  (адаптированы под функцию) + umbrella LICENSE.
- **Pack C:** English-primary README.md + README.ru.md во всех 4 тулах + umbrella;
  seedsplit README исправлен от вранья «scaffold» → честный v0.2.0.
- **Pack D:** seedsplit release — CHANGELOG.md, тег `v0.2.0`, Release с verified-ассетами
  (seedsplit + install.sh + SHA256SUMS), создан вручную через `gh` (без workflow-scope).
- **Pack E:** Homebrew `Formula/<tool>.rb` для 4 тулов (source-tarball, sha256 сверен с
  релизным tarball; securetrash Formula перепроверена — sha сходится).
- Финал: 2 независимых прогона тестов + перепроверка (shellcheck/vendor/флаги/крипта
  round-trip/reinstall) — всё зелёное.

## Статус gated-пунктов

1. **seedsplit CI/release workflow — ЗАКРЫТО ✓.** Токен получил `workflow`-scope,
   `ci.yml` + `release.yml` закоммичены и запушены. CI прогон зелёный. Теперь у всех 5
   репо CI = completed success.
2. **Публикация (этап 2)** — репо ghostdraft/seedsplit пока **private**. Делать public
   ТОЛЬКО по явному согласию Mr. Di (см. память [[publication-gate]]). После публикации:
   создать общий Homebrew-tap (`Di-kairos/homebrew-tap`) и перепроверить sha256 формул
   против публичных tarball'ов (стандартный publish-time шаг).

## Открытые вопросы (этап 2)

- **Монетизация** не решена (память [[monetization-open]]): платные фичи vs донат —
  отдельный брейншторм при маркетинговом раскрытии.

## Vendoring pin (общий)

Все тулы вендорят `securetrash/lib/common.sh` pin `2e3d2dd`. `tools/vendor-common.sh
--check` ловит дрейф — sync во всех 4 ✓.
