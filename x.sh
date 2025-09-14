#!/usr/bin/env bash
# Search for Venus Station branding references in Veilbreak-Frontier
# Excludes comments, venus mantrap/flytrap, statues of venus

cd "$(dirname "$0")" || exit 1

# Build ripgrep arguments
# -i : case-insensitive
# -n : show line numbers
# -H : show filename
# --no-heading : cleaner output
# -g : include all files
# --glob '!*.md' : skip docs if you want
# --glob '!*.yml' etc if you want to skip configs

rg -i -n -H --no-heading 'venus(?!\s*(mantrap|flytrap| statue| statues))' | rg -v '^\s*//' | rg -v '^\s*#' | rg -v '^\s*--' 
