module JavaScriptAssetsHelper
  # JavaScriptが読み込まれているかを確認するヘルパーメソッド
  def javascript_loaded?(script_name)
    page.evaluate_script("typeof #{script_name} !== 'undefined'")
  end

  # Stimulusコントローラーが登録されているかを確認するヘルパーメソッド
  def stimulus_controller_registered?(controller_name)
    page.evaluate_script("!!window.Stimulus && !!window.Stimulus.application.controllers.find(c => c.identifier === '#{controller_name}')")
  end

  # 特定のStimulusコントローラーを持つ要素が存在するかを確認するヘルパーメソッド
  def has_stimulus_controller?(controller_name)
    page.has_css?("[data-controller~=\"#{controller_name}\"]")
  end

  # Iconifyが正しく読み込まれているかを確認するヘルパーメソッド
  def iconify_loaded?
    page.evaluate_script("typeof customElements !== 'undefined' && !!customElements.get('iconify-icon')")
  end

  # アイコンが正しく表示されているかを確認するヘルパーメソッド
  def icon_rendered?(icon_name)
    page.has_css?("iconify-icon[icon=\"#{icon_name}\"]")
  end
end

RSpec.configure do |config|
  config.include JavaScriptAssetsHelper, type: :system
end
