# Tests for verify-releases.sh — the tool that tells a user whether the published releases are
# authentic. Its verdict is only worth what its failure paths are worth: before the 2026-09-07
# audit (F04) a release whose files did NOT download still counted as a PASS, and the final line
# claimed signatures AND files had been checked. These tests build a fixture release on disk,
# sign it with a throwaway key, and serve it over file:// (the PT_VERIFY_* seams).

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../verify-releases.sh"
  FIX="${BATS_TEST_TMPDIR}/rel"
  TAG="demo-v1.0.0"
  mkdir -p "$FIX/$TAG"
  ( cd "$FIX/$TAG"
    printf 'tool\n' > demo; printf 'installer\n' > install.sh
    printf 'twin\n' > demo.ps1; printf 'win installer\n' > install.ps1
    if command -v sha256sum >/dev/null 2>&1; then sha256sum demo install.sh demo.ps1 install.ps1 > SHA256SUMS
    else shasum -a 256 demo install.sh demo.ps1 install.ps1 > SHA256SUMS; fi )
  ssh-keygen -q -t ed25519 -N '' -C releases@paranoid-tools -f "${BATS_TEST_TMPDIR}/k" </dev/null
  ssh-keygen -Y sign -f "${BATS_TEST_TMPDIR}/k" -n file "$FIX/$TAG/SHA256SUMS" >/dev/null 2>&1
  export PT_VERIFY_BASE="file://$FIX"
  export PT_VERIFY_PUBKEY="$(cat "${BATS_TEST_TMPDIR}/k.pub" | cut -d' ' -f1,2)"
  export PT_VERIFY_SPECS="demo:1.0.0"
}

@test "a complete, correctly signed release passes and says all files matched" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4/4"* ]]
  [[ "$output" == *"1 ✓"* ]]
}

@test "a file that does not download is a FAILURE, not a pass (F04)" {
  # The exact reproduction from the audit: manifest and signature are fine, the program is gone.
  rm "$FIX/$TAG/demo"
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"не скачалось"* ]]
  [[ "$output" != *"1 ✓"* ]]
}

@test "the installers are verified too, not just the tool" {
  # Before F04 only the tool binary was checked: a swapped installer passed silently.
  printf 'evil\n' > "$FIX/$TAG/install.ps1"
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"install.ps1"* ]]
}

@test "a tampered file is caught even though the signature verifies" {
  printf 'evil\n' > "$FIX/$TAG/demo"
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"НЕ совпало с манифестом"* ]]
}

@test "a manifest signed by the wrong key is rejected" {
  ssh-keygen -q -t ed25519 -N '' -C releases@paranoid-tools -f "${BATS_TEST_TMPDIR}/other" </dev/null
  # ssh-keygen -Y sign PROMPTS before overwriting an existing .sig — remove it first, or the
  # signature under test stays the old (valid) one and the test silently checks nothing.
  rm -f "$FIX/$TAG/SHA256SUMS.sig"
  ssh-keygen -Y sign -f "${BATS_TEST_TMPDIR}/other" -n file "$FIX/$TAG/SHA256SUMS" >/dev/null 2>&1 </dev/null
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"подпись НЕ прошла"* ]]
}

@test "verifying nothing is not success" {
  PT_VERIFY_SPECS="" run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}
