#!/usr/bin/env bash

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $*"
}

require_file() {
  local file="$1"

  if [[ -f "${file}" ]]; then
    pass "file exists: ${file}"
  else
    fail "missing file: ${file}"
  fi
}

require_dir() {
  local dir="$1"

  if [[ -d "${dir}" ]]; then
    pass "directory exists: ${dir}"
  else
    fail "missing directory: ${dir}"
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if grep -Eq "${pattern}" "${file}"; then
    pass "${description}"
  else
    fail "${description} (${file})"
  fi
}

require_absent_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if grep -Eq "${pattern}" "${file}"; then
    fail "${description} (${file})"
  else
    pass "${description}"
  fi
}

finish_tests() {
  if [[ "${failures}" -ne 0 ]]; then
    echo "${failures} validation failure(s)." >&2
    exit 1
  fi

  echo "All validations passed."
}
