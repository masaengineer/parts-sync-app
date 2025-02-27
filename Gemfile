source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"
# The new asset pipeline for Rails [https://github.com/rails/propshaft]
# gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Devise for user authentication
gem "devise"

# Google OAuth2認証
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

gem "kaminari"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Advanced search functionality for Active Record
gem "ransack"

# Rails internationalization
gem "rails-i18n"

# Add mega-tags for enhanced SEOz
gem "meta-tags"

# OAuth2認証のため
gem "oauth2"
# HTTPクライアントとして使用
gem "faraday"

# sprocketsの追加
gem "sprockets-rails"

gem "sidekiq"
gem "sidekiq-scheduler"

gem "csv"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "faker"  # テストデータを生成するためのgem
  gem "factory_bot_rails"  # テストデータを生成するためのgem
  gem "pry-rails"
  gem "pry-byebug"

  # RSpec関連のgem
  gem "rspec-rails"  # Rails用のRSpec
  gem "spring-commands-rspec"  # Spring用のRSpecコマンド
  gem "shoulda-matchers"  # テストを簡潔に書くためのマッチャー
  gem "bundler-audit"  # セキュリティ監査のためのgem
  gem "rails-controller-testing"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "rails-erd"  # ER図を生成するためのgem
  gem "letter_opener"  # 開発環境でメールをブラウザで確認するためのgem
  gem "letter_opener_web"  # letter_openerをWeb経由で確認するためのgem
  gem "annotate"  # モデルファイルに対してスキーマ情報のコメントを自動生成するためのgem
  gem "overcommit"  # Git hooksを管理するためのgem
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
