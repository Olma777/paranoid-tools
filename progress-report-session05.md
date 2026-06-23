# Progress Report — Session 05

Date: 2026-06-23

## Сделано

### Аудит #3 — все 8 находок закрыты (5×P1 + 2×P2 + 1×P3)

**P1-1 — securetrash v0.4.2 (pubkey gap)**
Перевыпуск с корректным pubkey в ассетах. CI зелёный, `verify-releases.sh` проходит.

**P1-2 — Release signing fail-closed (полностью)**
- Все 5 `release.yml`: `exit 0→exit 1` при отсутствии `RELEASE_SIGNING_KEY`.
- `install.sh`: отсутствие `SHA256SUMS.sig` → `exit 1` (legacy escape: `ALLOW_UNSIGNED_LEGACY=1`).
- 2 новых bats-теста: absent-sig refusal + ALLOW_UNSIGNED_LEGACY pass-through.

**P1-3 — vaultwatch restore postconditions**
`cmd_stop`: `mdutil` failure captured → `restore_ok=0` → session state preserved. New i18n strings.
1 новый тест: mdutil fail keeps state.

**P1-4 — vaultwatch TTL postconditions**
`_ttl_schedule`: `return 1→return 0` (set -e compatible). `cmd_ttl_fire`: post-detach dir-check
перед `cmd_stop`. Новый `hdiutil` стаб симулирует реальный unmount.
2 новых теста: detach-fail keeps state; bootstrap-fail warns/no label.

**P1-5 — securetrash shred mount-root guard**
Post-esac guard в `_is_protected_path`: отказ для прямых детей `/Volumes/`.
Порядок проверок в `cmd_shred` переставлен: protected-before-existence.
2 новых теста: `/Volumes/ExternalDrive` и `/Volumes/SecretVault` refused.

**P2-1 — Windows reparse/junction guard**
`Remove-StItemSafe`: safe-delete без следования по reparse-точкам.
Pre-confirm check в `Invoke-StShred`: отказ если путь — junction/symlink.
`Invoke-StEmpty` тоже переключён на `Remove-StItemSafe`.
2 новых Pester: reparse refusal + safe-delete usage.

**P2-2 — `panic status` + `vaultwatch status`**
`panic status`: read-only preflight (образы, буфер, FileVault, cloud-демоны). 9 новых bats.
`vaultwatch status`: чтение `$VW_STATE_DIR`, показ активных сессий. 3 новых bats.
Новые стабы: `pbpaste`, `pgrep`, `fdesetup`.

**P2-3 — README версии / P3 ShellCheck SC2015**
README.md/README.ru.md: securetrash `v0.4.0→v0.4.2`.
smoke-test.sh + verify-releases.sh: 7 `A&&B||C` → `if/then/else`. shellcheck clean.

### Итоговая верификация

| Проверка | Результат |
|----------|-----------|
| bats (все 5 репо) | **215/215** |
| Pester (Windows) | **65/65** — CI |
| shellcheck | **clean** |
| AUDIT_FINDINGS.md | all `Status: CLOSED` |

## В процессе

Ничего не осталось незавершённым в рамках сессии.

## Остаток (для следующих сессий)

1. **Ручной интерактив-QA** (Mr. Di, `TESTING.md` §2): vault открытие с паролем,
   `ghostdraft new` с `$EDITOR`, vaultwatch хуки, `panic` disruptive.
2. **Бэкап ключа** (Mr. Di): `cp ~/paranoid-release-key /Volumes/SecretVault/` + `securetrash shred`.
3. **BitLocker hardware-smoke** — Windows-машина, не блокер.
4. **Этап 2 (go public)** — ТОЛЬКО по явному «да» Mr. Di: репо public + Homebrew tap sync (все 5 формул).
5. **Блок 3** — SLIP-39, passphrase-слой, decoy-vault. Сознательно отложено.

## Ключевые решения

- `ALLOW_UNSIGNED_LEGACY=1` как escape-хэтч для старых релизов — не флаг `--unsigned`, а env var:
  не попадает в shell history как явный аргумент.
- `Remove-StItemSafe` отказывает на самом reparse-point (не пытается удалить «только ссылку») —
  семантика shred неоднозначна для junction; пользователь должен явно указать реальный путь.
- `_ttl_schedule` возвращает 0 даже при ошибке (set -e совместимость в cmd substitution).
  Провал сигнализируется пустым stdout + warn-сообщением.
