# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # FactoryBotの設定を追加
  config.include FactoryBot::Syntax::Methods

  # Deviseのテストヘルパーを追加
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # テスト実行時のロケールを日本語に設定
  config.before(:each) do
    I18n.locale = :ja
  end

  # システムスペックの設定
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end

  # テストタグの設定
  # :slowタグ付きのテストを除外するフィルタ（CI環境やローカル開発で使用）
  config.filter_run_excluding slow: true if ENV['EXCLUDE_SLOW_TESTS'] == 'true'

  # :jsタグ付きのテストを除外するフィルタ（CI環境やローカル開発で使用）
  config.filter_run_excluding js: true if ENV['EXCLUDE_JS_TESTS'] == 'true'

  # 特定のグループのテストのみを実行するフィルタ
  if group = ENV['TEST_GROUP']
    config.filter_run_including group: group.to_sym
  end

  # テスト実行中のCapybaraの待機時間を調整
  # より安定したテスト実行のために待機時間を延長
  config.around(:each, type: :system) do |example|
    original_wait_time = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 5 # 必要に応じて調整
    example.run
    Capybara.default_max_wait_time = original_wait_time
  end

  # 失敗したテストのスクリーンショットを保存
  config.after(:each, type: :system) do |example|
    if example.exception && defined?(page) && page.respond_to?(:driver)
      # スクリーンショットが取得できる場合のみ実行
      begin
        page.save_screenshot(Rails.root.join("tmp/screenshots/#{example.full_description.gsub(/[^0-9A-Za-z]/, '_')}.png"))
      rescue Capybara::NotSupportedByDriverError => e
        puts "スクリーンショットの保存に失敗しました: #{e.message}"
      end
    end
  end
end

# Shoulda Matchers の設定
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Capybaraの設定追加
Capybara.server = :puma, { Silent: true }
# JavaScriptエラーが発生した場合にテストを失敗させる
Capybara.register_driver :selenium_chrome_headless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.add_argument('--headless')
  browser_options.add_argument('--no-sandbox')
  browser_options.add_argument('--disable-gpu')
  browser_options.add_argument('--disable-dev-shm-usage')
  browser_options.add_argument('--window-size=1400,1400')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
