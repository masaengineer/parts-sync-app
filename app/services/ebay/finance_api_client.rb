module Ebay
  class FinanceApiClient
    class FinanceError < StandardError; end  # エラークラスを追加

    API_BASE_URL = "https://apiz.ebay.com".freeze
    TRANSACTION_ENDPOINT = "/sell/finances/v1/transaction".freeze

    def initialize
      @auth_service = AuthService.new
    end

    def fetch_transactions(filters = {})
      Rails.logger.debug "fetch_transactions called with filters: #{filters}"
      all_transactions = []
      offset = 0
      limit = 1000  # eBay Finance APIの最大値を使用

      loop do
        response = client.get do |req|
          req.url TRANSACTION_ENDPOINT
          Rails.logger.debug "Request URL: #{TRANSACTION_ENDPOINT}"
          req.headers = auth_headers
          req.params = filters.merge(
            offset: offset,
            limit: limit
          )

          Rails.logger.debug "Request Headers: #{req.headers}"
          Rails.logger.debug "Request Params: #{req.params}"
        end

        result = JSON.parse(response.body)
        Rails.logger.debug "Response total: #{result['total']}"

        transactions = result["transactions"]
        break if transactions.nil? || transactions.empty?

        all_transactions.concat(transactions)
        offset += limit

        break if all_transactions.size >= result["total"].to_i
        # totalは指定されたフィルタ条件に一致する取引の総数（公式ドキュメントより）
      end

      Rails.logger.info "Total transactions fetched: #{all_transactions.size}"
      { "transactions" => all_transactions }

    rescue Faraday::Error => e
      Rails.logger.error "eBay Finance API Error: #{e.response&.body}"
      raise FinanceError, "取引情報取得エラー: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Unexpected Error in fetch_transactions: #{e.message}"
      raise FinanceError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def client
      @client ||= Faraday.new(url: API_BASE_URL) do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
      end
    end

    def auth_headers
      token = @auth_service.access_token
      raise ApiError, "アクセストークンの取得に失敗しました" if token.nil?

      {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    end
  end
end
