#!/usr/bin/env bash
# exit on error
set -e

echo "Installing dependencies..."
bundle install

echo "Installing JavaScript dependencies..."
yarn install

echo "Building JavaScript assets..."
yarn build

echo "Precompiling assets..."
RAILS_ENV=production bundle exec rake assets:precompile

echo "Cleaning assets..."
RAILS_ENV=production bundle exec rake assets:clean

echo "Running database migrations..."
RAILS_ENV=production bundle exec rake db:migrate

echo "Build completed successfully!"
