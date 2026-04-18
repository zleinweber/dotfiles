#!/usr/bin/env bash
set -euo pipefail

bash -n setup scripts/* recipes/*
shellcheck -x  scripts/* recipes/* setup
