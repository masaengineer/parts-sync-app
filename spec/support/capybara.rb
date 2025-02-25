require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')

  # Docker環境での追加設定
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--remote-debugging-port=9222')

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5

# テストサーバーのホスト設定（Docker環境では0.0.0.0を使用）
Capybara.server_host = '0.0.0.0'
Capybara.app_host = 'http://0.0.0.0:3000' if ENV['DOCKER_SYSTEM_SPEC']

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
