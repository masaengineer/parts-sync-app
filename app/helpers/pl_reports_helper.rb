module PlReportsHelper
  def format_metric_value(value, metric_key)
    case metric_key
    when :contribution_margin_rate
      number_with_precision(value, precision: 1) + "%"
    else
      number_to_currency(value, unit: "¥", precision: 0, format: "%u%n")
    end
  end
end
