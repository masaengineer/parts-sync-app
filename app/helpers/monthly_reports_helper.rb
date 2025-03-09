module MonthlyReportsHelper
  def format_metric_value(value, key)
    return "0" if value.nil?

    case key
    when :contribution_margin_rate
      "#{value}%"
    else
      number_to_currency(value, unit: "¥", precision: 0, delimiter: ",")
    end
  end

  # 翻訳キーからラベルを取得
  def metric_label(key)
    t("monthly_reports.metrics.#{key}")
  end

  # 値を通貨または割合形式でフォーマット
  def format_report_value(value, format_type)
    case format_type
    when :percentage
      number_to_percentage(value, precision: 0)
    else
      number_to_currency(value, unit: "¥", precision: 0)
    end
  end

  # メトリック値のフォーマット
  def format_metric_cell(value, format_type)
    format_report_value(value, format_type)
  end

  # 合計値のフォーマット
  def format_total_cell(value, format_type)
    format_report_value(value, format_type)
  end
end
