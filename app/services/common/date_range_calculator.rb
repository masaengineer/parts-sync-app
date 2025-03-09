module Common
  class DateRangeCalculator
    attr_reader :start_date, :end_date

    def initialize(start_date, end_date)
      @start_date = start_date
      @end_date = end_date
    end

    # 開始月から終了月までの月リストを取得
    def months_list
      start_month = @start_date.beginning_of_month.to_date
      end_month = @end_date.beginning_of_month.to_date

      months = []
      current_month = start_month

      while current_month <= end_month
        months << current_month
        current_month = current_month.next_month
      end

      months
    end

    # 二つの日付の間の年月の配列を返す
    def months_between
      start_month = Date.new(@start_date.year, @start_date.month, 1)
      end_month = Date.new(@end_date.year, @end_date.month, 1)

      result = []
      current = start_month

      while current <= end_month
        result << [ current.year, current.month ]
        current = current.next_month
      end

      result
    end
  end
end
