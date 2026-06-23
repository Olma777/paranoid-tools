# Paranoid Tools Audit Findings

Date: 2026-06-22
Mode: read-only audit; no code changes were made during the audit.

This file is intended for the developer who will fix the issues. `HANDOFF.md`
and `MANIFEST.md` are useful context, but this file is the actionable audit
queue.

## Summary

The macOS bash core is generally careful: destructive paths have guards,
`securetrash vault destroy` uses fail-closed mount-state checks, and `seedsplit`
has strong validation and integrity tests. The highest-risk issues are mostly
around operational guarantees, release/install trust, and documentation drift.

Validation performed during audit:

- `bats securetrash/test vaultwatch/test panic/test ghostdraft/test seedsplit/test`
  passed: 196/196.
- `bash -n` passed for the audited shell scripts.
- `bash verify-releases.sh` passed with GitHub access: all five release
  `SHA256SUMS.sig` files verified.
- `shellcheck` reported SC2015 in root harness scripts.
- Windows Pester tests were not run locally because `pwsh` is unavailable in
  this environment.
- Full `smoke-test.sh` was not run because it mounts `/Volumes/SecretVault`.

## Findings

### P1: `securetrash` v0.4.1 installer self-verify has an authenticity gap

`securetrash` release v0.4.1 is signed, but the release asset `install.sh` was
cut before the public key was embedded. As a result, the published v0.4.1
installer skips automatic signature verification even though main now contains
the fixed key.

Evidence:

- `HANDOFF.md:42-45` says v0.4.1 assets were cut before commit `81459ed`.
- `git -C securetrash show 62aac82:install.sh` has `RELEASE_SIGNING_PUBKEY=""`.
- Current `securetrash/install.sh:62` has the real Ed25519 public key.
- `verify-releases.sh` confirms the v0.4.1 `SHA256SUMS.sig` itself is valid.

Recommended fix:

- Publish a new `securetrash` tag/release, likely `v0.4.2`, from the commit that
  embeds the release public key.
- Update `MANIFEST.md`, `HANDOFF.md`, formulas, and docs to reference the new
  release.
- Consider making release signing mandatory in release workflows once the key is
  expected to exist.

### P1: Release signing is still optional in workflows and installers

All release workflows skip signing if `RELEASE_SIGNING_KEY` is unset, and
installers continue if `SHA256SUMS.sig` is absent. This preserves compatibility
with older releases, but for security tools it weakens the meaning of "signed
release" and allows future unsigned releases to look normal.

Evidence:

- `securetrash/.github/workflows/release.yml:33-40`
- `vaultwatch/.github/workflows/release.yml:32-39`
- `seedsplit/.github/workflows/release.yml:32-39`
- `securetrash/install.sh:75-77`
- Equivalent installer logic exists in `vaultwatch`, `panic`, `ghostdraft`, and
  `seedsplit`.

Recommended fix:

- Fail release jobs if `RELEASE_SIGNING_KEY` is missing.
- For new releases, fail installers when `.sig` is absent or signature
  verification cannot run, or provide an explicit legacy mode gated by version or
  opt-in env var.

### P1: `vaultwatch` restore can silently fail after `securetrash vault close`

`securetrash vault close` detaches the image first, then invokes `post-close`.
`vaultwatch stop` then tries to restore Spotlight and Time Machine settings
against a mountpoint that may no longer exist, while ignoring errors. This can
leave system settings changed while reporting a clean session close.

Evidence:

- `securetrash/securetrash:551-555` detaches before running `post-close`.
- `vaultwatch/vaultwatch:517-518` restores with `mdutil`/`tmutil` and ignores
  failures.
- `vaultwatch/vaultwatch:520-537` prints the report and deletes state anyway.

Recommended fix:

- Run a pre-close hook before detach, or make `vaultwatch stop` restore using
  durable identifiers/paths that still work after detach.
- Verify restoration postconditions before deleting the session state.
- Report partial restore failures loudly and keep enough state for retry.

### P1: `vaultwatch` TTL can mark a session closed even when detach failed

`_ttl_schedule` ignores `launchctl bootstrap` failure. `_ttl_fire` ignores
`hdiutil detach` failure and then calls `cmd_stop`, which restores and deletes
state. The user may believe the vault was auto-detached when it was not.

Evidence:

- `vaultwatch/vaultwatch:411-412` ignores `launchctl` failure.
- `vaultwatch/vaultwatch:555-565` calls `hdiutil detach ... || true`.
- `vaultwatch/vaultwatch:567-568` calls `cmd_stop` unconditionally after detach
  attempt.

Recommended fix:

- Treat launchd schedule failure as a visible warning or hard failure for
  `--ttl`.
- After TTL detach, verify the volume is actually gone before calling
  `cmd_stop`.
- If detach fails, keep session state and report the failure.

### P1: `securetrash shred` can delete an entire mounted volume

The protected-path guard blocks `/Volumes` itself, but not mount roots such as
`/Volumes/SecretVault` or `/Volumes/ExternalDrive`. A mistaken `securetrash shred`
against a mount root can recursively delete the whole mounted volume.

Evidence:

- `securetrash/securetrash:402-417` protects `/Volumes` but not direct children
  under `/Volumes`.
- `securetrash/securetrash:439` calls `_shred_path` on validated targets.
- `securetrash/securetrash:346-351` uses `chmod -R` and `rm -rfP`.

Recommended fix:

- Refuse direct mount roots by default.
- Allow explicit override only with a very deliberate flag, if needed.
- Add tests for `/Volumes/<mount>` and the securetrash vault mountpoint.

### P2: Windows protected-path guard does not resolve junctions/reparse points

The Windows beta guard normalizes with `GetFullPath`, but explicitly does not
resolve junctions/symlinks. `Invoke-StShred` then deletes recursively via
`Remove-Item -LiteralPath -Recurse -Force`. This is risky around reparse points
and protected targets.

Evidence:

- `securetrash/windows/securetrash.ps1:594-599`
- `securetrash/windows/securetrash.ps1:633-645`

Recommended fix:

- Detect and reject reparse points by default.
- Resolve final targets before allowing recursive deletion where possible.
- Add Pester tests for junctions/symlinks and dangerous Windows paths.

### P2: Documentation references commands that do not exist

`TESTING.md` tells users to run `vaultwatch status` and `panic status`, but both
CLIs reject `status` as an unknown command. For `panic`, this is especially bad
because the docs describe it as a safe read-only preview before a disruptive
operation.

Evidence:

- `TESTING.md:70`
- `TESTING.md:82`
- `panic/panic:244-253` only dispatches `version`, `help`, and `now`.
- `vaultwatch/vaultwatch:573-585` has no `status` dispatch.

Recommended fix:

- Either implement `status` for both tools, or remove those commands from docs.
- For `panic`, prefer implementing a real read-only preview because the docs
  already position it as the safe preflight.

### P2: Version and release documentation is stale

Top-level README files still list old versions while the executable files and
`MANIFEST.md` show newer versions.

Evidence:

- `README.md:16-20` lists `securetrash v0.4.0` and `seedsplit v0.2.0`.
- `README.ru.md:15-19` has the same drift.
- Actual versions verified during audit:
  - `securetrash 0.4.1`
  - `vaultwatch 0.1.1`
  - `panic 0.1.1`
  - `ghostdraft 0.1.1`
  - `seedsplit 0.3.0`

Recommended fix:

- Update top-level README tables.
- Search docs for stale examples like `ST_VERSION=0.4.0`,
  `SEEDSPLIT_VERSION=0.2.0`, and `securetrash 0.2.0 (Windows, beta)`.

### P3: Root harness scripts trigger ShellCheck SC2015

`shellcheck` reports `A && B || C` patterns in `smoke-test.sh` and
`verify-releases.sh`. These are common but can produce false results if the
successful branch returns non-zero.

Evidence:

- `smoke-test.sh:41`
- `smoke-test.sh:42`
- `smoke-test.sh:51`
- `smoke-test.sh:54`
- `smoke-test.sh:62`
- `smoke-test.sh:85`
- `verify-releases.sh:36`

Recommended fix:

- Rewrite these as explicit `if ...; then ...; else ...; fi` blocks.
- Add root-level lint to CI if these scripts are intended to stay release-grade.

## Lower Priority Notes

- The repository contains nested full `.git` directories rather than submodules.
  This is intentional per `.gitignore`, but it makes umbrella status/release
  snapshots drift-prone. Keep `MANIFEST.md` authoritative but easy to regenerate.
- `.DS_Store` files exist in several working trees and `.git` directories. They
  are ignored, but cleanup is useful before packaging/publication.
- Windows Pester coverage is mocked and not a substitute for BitLocker/VHDX
  hardware validation. Existing docs already state this; keep that caveat visible.

## Suggested Fix Order

1. Release `securetrash v0.4.2` with embedded signing pubkey in release assets.
2. Decide whether signatures are mandatory for all future releases; enforce that
   in workflows/installers.
3. Fix `vaultwatch` close/TTL postconditions so state is not deleted after a
   failed restore or failed detach.
4. Add mount-root refusal to `securetrash shred`.
5. Fix or implement `status` commands in docs/CLI.
6. Refresh README versions and stale install examples.
7. Clean up ShellCheck SC2015 in root QA scripts.
