module Ebay
  class EbayFinanceClient
    class FinanceError < StandardError; end  # エラークラスを追加

    API_BASE_URL = "https://apiz.ebay.com".freeze
    TRANSACTION_ENDPOINT = "/sell/finances/v1/transaction".freeze

    def initialize
      @auth_service = EbayAuthClient.new
    end

    def fetch_transactions(filters = {})
      Rails.logger.debug "fetch_transactions called with filters: #{filters}"
      all_transactions = []
      offset = 0
      limit = 200 # バッチサイズを1000から200に削減
      max_transactions = 10000 # 最大取得件数制限

      loop do
        Rails.logger.info "📥 eBay Finance API - offset: #{offset}, limit: #{limit}"

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

        Rails.logger.info "📊 取得済み件数: #{all_transactions.size} / #{result['total']}"

        # 最大件数制限チェック
        if all_transactions.size >= max_transactions
          Rails.logger.warn "⚠️  最大取得件数(#{max_transactions})に達しました。処理を停止します。"
          break
        end

        break if all_transactions.size >= result["total"].to_i
      end

      Rails.logger.info "Total transactions fetched: #{all_transactions.size}"
      { "transactions" => all_transactions }

    rescue Faraday::Error => e
      Rails.logger.error "eBay Finance API Error: #{e.response&.body}"
      Rails.logger.error "Error class: #{e.class.name}"
      Rails.logger.error "Error message: #{e.message}"
      raise FinanceError, "取引情報取得エラー: #{e.message}"
    rescue Net::ReadTimeout => e
      Rails.logger.error "eBay Finance API Timeout: #{e.message}"
      raise FinanceError, "API応答タイムアウト: #{e.message}"
    rescue Net::OpenTimeout => e
      Rails.logger.error "eBay Finance API Connection Timeout: #{e.message}"
      raise FinanceError, "API接続タイムアウト: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Unexpected Error in fetch_transactions: #{e.message}"
      Rails.logger.error "Error class: #{e.class.name}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
      raise FinanceError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def client
      @client ||= Faraday.new(url: API_BASE_URL) do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 300 # 5分のタイムアウト
        faraday.options.open_timeout = 60 # 1分の接続タイムアウト
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
