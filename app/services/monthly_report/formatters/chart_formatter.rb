module MonthlyReport
  module Formatters
    class ChartFormatter
      attr_reader :monthly_data

      def initialize(monthly_data)
        @monthly_data = monthly_data
      end

      def format
        {
          labels: monthly_data.map { |m| "#{m[:year]}/#{m[:month]}" },
          datasets: [
            {
              key: :revenue,
              label: "売上高",
              data: monthly_data.map { |m| m[:revenue] }
            },
            {
              key: :contribution_margin,
              label: "限界利益",
              data: monthly_data.map { |m| m[:contribution_margin] }
            }
          ]
        }
      end
    end
  end
end
