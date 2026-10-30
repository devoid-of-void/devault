#!/usr/bin/env bash
# Non-destructive static and CLI smoke checks: no block devices touched.
set -Eeuo pipefail
cd -- "$(dirname -- "$0")/.."

bash -n ./devault

if output=$(bash ./devault 2>&1); then
    echo 'FAIL: invoking without arguments should not succeed' >&2
    exit 1
fi
[[ $output == *'devault create FILE'* ]] || {
    echo 'FAIL: usage output is missing' >&2
    exit 1
}
if output=$(bash ./devault unusual-command /does/not/exist 2>&1); then
    echo 'FAIL: invalid command should not succeed' >&2
    exit 1
fi
[[ $output == *'Usage:'* ]] || {
    echo 'FAIL: invalid command did not print usage' >&2
    exit 1
}
echo 'PASS: syntax and command-line usage'
