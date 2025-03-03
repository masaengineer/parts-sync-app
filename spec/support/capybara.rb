require 'capybara/rspec'
require 'selenium-webdriver'

# Docker環境では、リモートブラウザを使用
if ENV['DOCKER_SYSTEM_SPEC']
  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1400,1400')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options
    )
  end
else
  # ローカル環境の設定
  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options
    )
  end
end

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5

# Capybaraのサーバー設定
Capybara.server = :puma, { Silent: true }

# Docker環境ではホスト設定を調整
if ENV['DOCKER_SYSTEM_SPEC']
  # テストサーバーは同じコンテナ内で起動するため0.0.0.0を指定
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 4000
  # アプリケーションアドレスも同様
  Capybara.app_host = 'http://0.0.0.0:4000'
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
