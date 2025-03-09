module MonthlyReport
  module Formatters
    class TableFormatter
      attr_reader :monthly_data, :totals

      def initialize(monthly_data, totals)
        @monthly_data = monthly_data
        @totals = totals
      end

      def format
        # 月ごとのヘッダーを作成
        headers = monthly_data.map { |data| "#{data[:year]}年#{data[:month]}月" }

        # 各指標のデータを抽出
        metrics = [
          { key: :revenue, format: :currency, values: monthly_data.map { |data| data[:revenue] } },
          { key: :procurement_cost, format: :currency, values: monthly_data.map { |data| data[:procurement_cost] } },
          { key: :gross_profit, format: :currency, values: monthly_data.map { |data| data[:gross_profit] } },
          { key: :expenses, format: :currency, values: monthly_data.map { |data| data[:expenses] } },
          { key: :contribution_margin, format: :currency, values: monthly_data.map { |data| data[:contribution_margin] } },
          { key: :contribution_margin_rate, format: :percentage, values: monthly_data.map { |data| data[:contribution_margin_rate] } }
        ]

        {
          headers: headers,
          metrics: metrics,
          totals: totals
        }
      end
    end
  end
end
