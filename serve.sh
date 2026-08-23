#!/usr/bin/env bash
cd "$(dirname "$0")"
source .venv/bin/activate
mkdocs serve -a 127.0.0.1:8000
