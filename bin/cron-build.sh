#!/usr/bin/env bash
# exit on error
set -o errexit

echo "=== Setting up environment for cron job ==="
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"
echo "Current directory: $(pwd)"

echo "=== Installing dependencies ==="
bundle config set --local path '.gems'
bundle install

echo "=== Verifying installation ==="
bundle list | head -10

echo "=== Build completed successfully ==="