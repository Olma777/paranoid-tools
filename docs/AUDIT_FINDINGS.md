# Paranoid Tools Audit Findings

Audit date: 2026-06-22. Fixes applied: 2026-06-23.

Original audit validated:
- `bats` 196/196 across all 5 repos.
- `bash -n` on all shell scripts.
- `verify-releases.sh` — all 5 `SHA256SUMS.sig` valid.
- `shellcheck` reported SC2015 in root harness scripts.
- Windows Pester not run locally (no `pwsh`); CI validates.

Post-fix state: **215/215 bats** (196 original + 19 new) · **65 Pester** (63 original + 2 new) ·
**shellcheck clean** · CI green across all 5 repos.

---

## P1 Findings

### P1-1: `securetrash` v0.4.1 installer self-verify pubkey gap

**Status: CLOSED** · `securetrash` `d70802d`

v0.4.1 assets were cut before pubkey was embedded; installer skipped self-verify.

Fix: released v0.4.2 (`2f40015`) with correct pubkey in all release assets.
Verified: `verify-releases.sh` confirms v0.4.2 sig valid.

---

### P1-2: Release signing optional in workflows and installers

**Status: CLOSED** · all 5 repos · `securetrash` `d70802d`

Workflows silently skipped signing (`exit 0`) when `RELEASE_SIGNING_KEY` absent.
Installer continued installation when `SHA256SUMS.sig` absent.

Fixes:
- All 5 `release.yml`: `exit 0 → exit 1` when key absent. CI fails if key is missing.
- `install.sh`: absent `SHA256SUMS.sig` now `exit 1`. Legacy escape: `ALLOW_UNSIGNED_LEGACY=1`.
- "No .sig" warning moved from stdout → stderr.

Tests: 2 new `install.bats` tests — absent-sig refusal + `ALLOW_UNSIGNED_LEGACY=1` pass-through.
3 existing checksum tests updated to use `ALLOW_UNSIGNED_LEGACY=1` (they test checksum, not signing).

---

### P1-3: `vaultwatch` restore silently fails after vault close

**Status: CLOSED** · `vaultwatch` `ea35706`

`cmd_stop` used `mdutil ... || true`, deleted session state even on restore failure.

Fixes:
- `cmd_stop`: `mdutil` failure captured, `restore_ok=0`, session state kept on failure.
- New i18n strings: `restore_spot_fail`, `restore_incomplete`.
- `tmutil removeexclusion` keeps `|| true` (path-based, still works post-detach).

Tests: 1 new `watch.bats` — "mdutil fail keeps state and warns".

---

### P1-4: `vaultwatch` TTL marks session closed even when detach failed

**Status: CLOSED** · `vaultwatch` `ea35706`

`_ttl_schedule` ignored `launchctl bootstrap` failure; `_ttl_fire` called `cmd_stop`
unconditionally after `hdiutil detach` without verifying unmount.

Fixes:
- `_ttl_schedule`: `return 1 → return 0` after bootstrap fail (avoids `set -e` kill);
  empty stdout signals failure to caller; warn emitted.
- `cmd_ttl_fire`: post-detach `[[ -d "$mount" ]]` check — if dir still exists, detach
  failed; warn + `return 1` (keep state). Only calls `cmd_stop` when dir is gone.
- New i18n strings: `ttl_detach_fail`, `ttl_sched_fail`.

Tests: 2 new `ttl.bats` — detach-fail keeps state; bootstrap-fail warns/no label.

---

### P1-5: `securetrash shred` can delete an entire mounted volume

**Status: CLOSED** · `securetrash` `d70802d`

`_is_protected_path` blocked `/Volumes` but not `/Volumes/<name>` (direct mount roots).

Fix: post-`esac` guard in `_is_protected_path` — strips `/Volumes/` prefix, refuses if
remainder contains no `/` (direct child = mount root). Also swapped check order in
`cmd_shred`: protected-before-existence (enables testing with non-existent paths).

Tests: 2 new `securetrash.bats` — `/Volumes/ExternalDrive` and `/Volumes/SecretVault` refused.

---

## P2 Findings

### P2-1: Windows protected-path guard does not handle reparse points

**Status: CLOSED** · `securetrash` `a8eec63`

`GetFullPath` does not resolve reparse points; `Remove-Item -Recurse` in PS 5.1 follows
junctions and deletes target contents.

Fixes:
- `Remove-StItemSafe`: new helper — recursive delete that removes junction/symlink entry
  only (not target), never follows reparse points.
- `Invoke-StShred`: pre-confirm check `[IO.FileAttributes]::ReparsePoint` → refusal with
  `shred_reparse` message (EN+RU) if target path is itself a reparse point.
- `Invoke-StShred` + `Invoke-StEmpty`: `Remove-Item -Recurse → Remove-StItemSafe`.
- Updated ASSUMPTION comment — GetFullPath behavior is now intentional, not a gap.

Tests: 2 new Pester — reparse guard refusal + `Remove-StItemSafe` usage verification.

---

### P2-2: Documentation references non-existent `status` commands

**Status: CLOSED** · `panic` `e1771de` · `vaultwatch` `ea35706`

`TESTING.md` referenced `panic status` and `vaultwatch status`; both dispatchers
rejected "status" as unknown.

Fixes:
- `panic status`: `cmd_status` — read-only preflight showing mounted images, clipboard
  state, FileVault, running cloud daemons. No destructive calls.
- `vaultwatch status`: `cmd_status` — reads `$VW_STATE_DIR/*.state`, shows active sessions
  with mount, elapsed time, Spotlight state, TM exclusion, TTL countdown.
- Usage strings and dispatch updated in both tools.

Tests: 9 new `panic/test/status.bats` + 3 new `vaultwatch/test/watch.bats` status tests.
New stubs: `pbpaste`, `pgrep`, `fdesetup` for panic.

---

### P2-3: Version and release documentation stale

**Status: CLOSED** · umbrella `29cf9b2`

`README.md` and `README.ru.md` listed `securetrash v0.4.0` (current: v0.4.2).

Fix: updated both README tables to `v0.4.2`.

---

## P3 Findings

### P3-1: Root harness scripts trigger ShellCheck SC2015

**Status: CLOSED** · umbrella `29cf9b2`

`A && B || C` patterns in `smoke-test.sh` (6 occurrences) and `verify-releases.sh` (1).

Fix: rewrote all 7 as explicit `if ...; then ...; else ...; fi` blocks.
Verified: `shellcheck smoke-test.sh verify-releases.sh` — clean.

---

## Lower Priority Notes

- Nested `.git` dirs vs submodules: intentional per `.gitignore`. `RELEASE-STATE.md` is
  the authoritative convenience snapshot.
- `.DS_Store` files: ignored, cleanup useful before publication.
- Windows Pester mocked: not a substitute for BitLocker/VHDX hardware validation.
  Caveat documented in `TESTING.md`.

---

## Verification Matrix

| Check | Result |
|-------|--------|
| `bats` all 5 repos | **215/215** (was 196) |
| Pester (securetrash Windows) | **65/65** (was 63) — CI validates |
| `shellcheck` install.sh securetrash vaultwatch panic | **clean** |
| `shellcheck` smoke-test.sh verify-releases.sh | **clean** |
| `verify-releases.sh` | all 5 sigs valid (run with GH access) |
| Windows Pester CI | green on `windows-latest` |
