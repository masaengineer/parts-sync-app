module Ebay
  class MockEbayFinanceClient
    class FinanceError < StandardError; end

    def initialize
      @mock_data_path = Rails.root.join("app", "services", "ebay", "mock_data", "mock_transactions.json")
      load_mock_data
    end

    def fetch_transactions(filters = {})
      Rails.logger.debug "モックFinanceクライアント: fetch_transactions called with filters: #{filters}"

      begin
        # モックデータが正常に読み込まれたか確認
        if @mock_data.nil? || !@mock_data.key?("transactions")
          raise FinanceError, "モックデータの読み込みに失敗しました"
        end

        # フィルタリングされたトランザクションを返す
        # 実際のAPIと同様に動作させるためのフィルタリング処理
        transactions = filter_transactions(@mock_data["transactions"], filters)

        Rails.logger.info "モックデータから #{transactions.size} 件のトランザクションを取得しました"
        { "transactions" => transactions }
      rescue StandardError => e
        Rails.logger.error "モックFinanceクライアントエラー: #{e.message}"
        raise FinanceError, "予期せぬエラーが発生しました: #{e.message}"
      end
    end

    private

    def load_mock_data
      begin
        file_content = File.read(@mock_data_path)
        @mock_data = JSON.parse(file_content)
        Rails.logger.info "モックデータを読み込みました: #{@mock_data_path}"
      rescue Errno::ENOENT
        Rails.logger.error "モックデータファイルが見つかりません: #{@mock_data_path}"
        @mock_data = nil
      rescue JSON::ParserError
        Rails.logger.error "モックデータのJSONパースエラー: #{@mock_data_path}"
        @mock_data = nil
      rescue StandardError => e
        Rails.logger.error "モックデータ読み込み中の予期せぬエラー: #{e.message}"
        @mock_data = nil
      end
    end

    # フィルター条件に基づいてトランザクションをフィルタリングする簡易実装
    def filter_transactions(transactions, filters)
      filtered_transactions = transactions

      # トランザクションタイプでフィルタリング
      if filters[:transaction_type]
        filtered_transactions = filtered_transactions.select { |t| t["transactionType"] == filters[:transaction_type] }
      end

      # 日付範囲でフィルタリング
      if filters[:transaction_date_from] && filters[:transaction_date_to]
        from_date = Time.parse(filters[:transaction_date_from])
        to_date = Time.parse(filters[:transaction_date_to])

        filtered_transactions = filtered_transactions.select do |t|
          transaction_date = Time.parse(t["transactionDate"])
          transaction_date >= from_date && transaction_date <= to_date
        end
      end

      filtered_transactions
    end
  end
end
