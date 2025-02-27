module MonthlyReportsHelper
  def format_metric_value(value, key)
    return '0' if value.nil?

    case key
    when :contribution_margin_rate
      "#{value}%"
    else
      number_to_currency(value, unit: '¥', precision: 0, delimiter: ',')
    end
  end
end
