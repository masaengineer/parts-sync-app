#!/bin/bash
set -x  # デバッグモード

echo "=== DEBUG: Starting cron job ==="
echo "Date: $(date)"
echo "PWD: $(pwd)"
echo "Ruby: $(which ruby)"
echo "Bundle: $(which bundle)"
echo "DATABASE_URL exists: $(if [ -n "$DATABASE_URL" ]; then echo "YES"; else echo "NO"; fi)"

echo "=== DEBUG: Checking bundle ==="
bundle check || bundle install

echo "=== DEBUG: Running rake without timeout ==="
bundle exec rake ebay:sync_all --trace

exit_code=$?
echo "=== DEBUG: Exit code: $exit_code ==="


exit $exit_code