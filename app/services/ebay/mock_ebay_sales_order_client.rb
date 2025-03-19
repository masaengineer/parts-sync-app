module Ebay
  class MockEbaySalesOrderClient
    class FulfillmentError < StandardError; end

    def initialize
      @mock_data_path = Rails.root.join('app', 'services', 'ebay', 'mock_data', 'mock_orders.json')
      load_mock_data
    end

    # モックされた注文データを取得する
    # @param current_user [User] 現在のユーザー
    # @return [Hash] 注文データと最終同期日時
    def fetch_orders(current_user)
      begin
        # モックデータが正常に読み込まれたか確認
        if @mock_data.nil? || !@mock_data.key?('orders')
          raise FulfillmentError, "モックデータの読み込みに失敗しました"
        end

        # 現在のUTC時刻を取得（最終同期日時として使用）
        current_time_utc = Time.now.utc

        # モックデータと最終同期日時を返す
        { orders: @mock_data['orders'], last_synced_at: current_time_utc }
      rescue StandardError => e
        raise FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
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
  end
end
