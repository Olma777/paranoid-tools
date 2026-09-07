# Tests for the panic core (pack 2: now — detach images, clipboard, lock screen).
# System commands are replaced with stubs via PATH (+ PANIC_CGSESSION), so the
# tests run deterministically even on Linux CI.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../panic"
  STUBS="${BATS_TEST_DIRNAME}/stubs"
  TMP="$(mktemp -d)"
  export VW_STUB_LOG="$TMP/calls.log"
  export PANIC_CGSESSION="$STUBS/cgsession"
  export PATH="$STUBS:$PATH"
  export ST_ASSUME_YES=1
  unset ST_LANG
}

teardown() { rm -rf "$TMP"; }

run_now() { run env PATH="$STUBS:$PATH" PANIC_CGSESSION="$STUBS/cgsession" bash "$SCRIPT" now "$@"; }

@test "now detaches each mounted /Volumes disk image" {
  STUB_MOUNTS="/Volumes/SecretVault|/Volumes/Other" run_now
  [ "$status" -eq 0 ]
  grep -qF -- "detach -force /Volumes/SecretVault" "$VW_STUB_LOG"
  grep -qF -- "detach -force /Volumes/Other" "$VW_STUB_LOG"
}

@test "now does NOT detach a system image mounted outside /Volumes" {
  STUB_MOUNTS="/|/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  grep -qF -- "detach -force /Volumes/SecretVault" "$VW_STUB_LOG"
  ! grep -qE "detach -force /$" "$VW_STUB_LOG"
}

@test "now preserves a mountpoint with spaces" {
  STUB_MOUNTS="/Volumes/Secret Vault" run_now
  [ "$status" -eq 0 ]
  grep -qF -- "detach -force /Volumes/Secret Vault" "$VW_STUB_LOG"
}

@test "now clears the clipboard" {
  STUB_MOUNTS="/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  grep -q "pbcopy" "$VW_STUB_LOG"
}

@test "now locks the screen" {
  STUB_MOUNTS="/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  grep -qF -- "cgsession -suspend" "$VW_STUB_LOG"
}

@test "now with no mounted images still clears clipboard and locks" {
  STUB_MOUNTS="" run_now
  [ "$status" -eq 0 ]
  ! grep -q "detach" "$VW_STUB_LOG"
  grep -q "pbcopy" "$VW_STUB_LOG"
  grep -qF -- "cgsession -suspend" "$VW_STUB_LOG"
}

@test "now reports what it did" {
  STUB_MOUNTS="/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  [[ "$output" == *"clipboard"* ]] || [[ "$output" == *"буфер"* ]]
  [[ "$output" == *"lock"* ]] || [[ "$output" == *"заперт"* ]] || [[ "$output" == *"экран"* ]]
}

# --- lock honesty (regression: CGSession used to fail silently while the report lied "locked") ---

@test "now falls back to osascript Ctrl+Cmd+Q when CGSession is missing" {
  STUB_MOUNTS="" run env PATH="$STUBS:$PATH" \
    PANIC_CGSESSION="$TMP/nonexistent-cgsession" PANIC_OSASCRIPT="$STUBS/osascript" \
    bash "$SCRIPT" now
  [ "$status" -eq 0 ]
  grep -qF -- "osascript" "$VW_STUB_LOG"
  [[ "$output" == *"locked"* ]] || [[ "$output" == *"заблокирован"* ]]
}

@test "now honestly warns when the screen could NOT be locked" {
  STUB_MOUNTS="" run env PATH="$STUBS:$PATH" \
    PANIC_CGSESSION="$TMP/nonexistent-cgsession" PANIC_OSASCRIPT="$STUBS/osascript" OSASCRIPT_EXIT=1 \
    bash "$SCRIPT" now
  [ "$status" -eq 0 ]                       # panic does not fail even if the lock failed
  [[ "$output" == *"could NOT lock"* ]] || [[ "$output" == *"НЕ удалось заблокировать"* ]]
  [[ "$output" != *"screen locked"* ]]      # and does NOT lie about success
}

@test "now falls back to osascript when CGSession exists but returns non-zero" {
  # The CGSession binary exists, but -suspend failed (CGSESSION_EXIT=1) → must fall back to osascript.
  STUB_MOUNTS="" run env PATH="$STUBS:$PATH" \
    PANIC_CGSESSION="$STUBS/cgsession" CGSESSION_EXIT=1 PANIC_OSASCRIPT="$STUBS/osascript" \
    bash "$SCRIPT" now
  [ "$status" -eq 0 ]
  grep -qF -- "osascript" "$VW_STUB_LOG"     # the fallback was actually invoked
  [[ "$output" == *"locked"* ]] || [[ "$output" == *"заблокирован"* ]]
}

@test "now exit code survives a closed pipe (no SIGPIPE 141 from multi-line report)" {
  # Regression: the report's second stdout line (lock_ok) under pipefail `panic now | head -n1`
  # dropped the exit code to 141 even though the panic succeeded. Report is best-effort → pipeline status 0.
  STUB_MOUNTS="/Volumes/SecretVault" run env PATH="$STUBS:$PATH" \
    PANIC_CGSESSION="$STUBS/cgsession" \
    bash -o pipefail -c '"'"$SCRIPT"'" now | head -n1'
  [ "$status" -eq 0 ]
}

# Аудит 2026-09-07, F09: «мгновенно» было намерением, а не измеренной характеристикой.
# Отчёт теперь называет реальное время двух шагов этого запуска.
@test "now reports the measured time of the detach and of the screen lock (F09)" {
  STUB_MOUNTS="/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  [[ "$output" =~ images\ detached\ after\ [0-9]+\.[0-9][0-9]\ s ]]
  [[ "$output" =~ lock\ step\ finished\ after\ [0-9]+\.[0-9][0-9]\ s ]]
}

@test "the volumes are closed BEFORE the screen is locked, not after" {
  # A locked screen over a mounted vault protects nothing from someone who takes the machine
  # away; the order is a decision, so it is pinned by a test rather than left to chance.
  STUB_MOUNTS="/Volumes/SecretVault" run_now
  [ "$status" -eq 0 ]
  detach_line="$(grep -n -- "detach -force /Volumes/SecretVault" "$VW_STUB_LOG" | head -1 | cut -d: -f1)"
  lock_line="$(grep -n -- "cgsession" "$VW_STUB_LOG" | head -1 | cut -d: -f1)"
  [ -n "$detach_line" ]
  [ -n "$lock_line" ]
  [ "$detach_line" -lt "$lock_line" ]
}

@test "the timing report survives a missing perl (whole seconds, never a crash)" {
  # perl ships with macOS, but panic must not fail because a clock helper is absent.
  fake="$(mktemp -d)"
  for c in hdiutil pbcopy pkill mount; do ln -sf "$STUBS/$c" "$fake/$c" 2>/dev/null || true; done
  run env PATH="$STUBS:/usr/bin:/bin" PANIC_CGSESSION="$STUBS/cgsession" \
        STUB_MOUNTS="/Volumes/SecretVault" \
        bash -c "perl() { return 127; }; export -f perl 2>/dev/null; bash '$SCRIPT' now"
  [ "$status" -eq 0 ]
  [[ "$output" == *"timing:"* ]]
  rm -rf "$fake"
}
