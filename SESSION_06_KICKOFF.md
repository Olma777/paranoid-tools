# Session 06 Kickoff

## Что читать первым

1. `HANDOFF.md` — снимок состояния (HEAD всех репо, bats/Pester счётчики).
2. `AUDIT_FINDINGS.md` — все 8 находок `Status: CLOSED`, верификационная матрица.
3. `progress-report-session05.md` — детали что/почему сделано в сессии 5.

## Снимок на момент закрытия (2026-06-23)

| Репо | HEAD | bats/Pester |
|------|------|-------------|
| umbrella | `af67535` | — |
| securetrash | `d70802d` | 63/63 bats + 65/65 Pester |
| vaultwatch | `447dca2` | 56/56 bats |
| panic | `1e2d06f` | 33/33 bats |
| ghostdraft | `63bfd48` | 26/26 bats |
| seedsplit | `1e2c3f1` | 37/37 bats |

**Всего: 215/215 bats · 65/65 Pester · shellcheck clean · CI green**

Все 5 репо PRIVATE. Подписи live. `verify-releases.sh` — 5/5 ✅

## Фокус сессии 06

**Ближайшие задачи (не блокеры, но логичный следующий шаг):**

1. `smoke-test.sh` полный прогон (нужен живой `/Volumes/SecretVault` — задача Mr. Di).
2. Если Mr. Di даёт «да» на публикацию → Этап 2:
   - Все 5 репо public.
   - Homebrew tap `Di-kairos/homebrew-tap` — добавить формулы для vaultwatch/panic/ghostdraft/seedsplit
     (сейчас только securetrash.rb, и он указывает на старый тег).
   - Public install-smoke: `curl|bash install.sh` + `brew install`.
3. Блок 3 (roadmap): SLIP-39, passphrase-слой, decoy-vault — по решению Mr. Di.

**Нет открытых технических долгов по аудиту.**

## Project Knowledge для загрузки

- `HANDOFF.md`
- `AUDIT_FINDINGS.md`
- `progress-report-session05.md`
- `securetrash/CLAUDE.md` (если работа в securetrash)
