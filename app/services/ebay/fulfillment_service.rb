module Ebay
  class FulfillmentService
    class FulfillmentError < StandardError; end

    API_ENDPOINT = "/sell/fulfillment/v1/order".freeze

    def initialize
      @auth_service = AuthService.new
      Rails.logger.debug "Ebay::FulfillmentService initialized" # 初期化ログ
      validate_auth_token
    end

    def fetch_orders(current_user)
      all_orders = []
      offset = 0
      limit = 200 # APIの最大値
      loop_count = 0

      # 現在のUTC時刻を取得
      current_time_utc = Time.now.utc
      # 1年半前のUTC時刻を取得し、1日分のバッファを追加
      two_years_ago_utc = (current_time_utc - 18.months + 1.day)

      # 最終同期日時を取得（UTCに変換）
      last_synced_at = current_user.ebay_orders_last_synced_at&.utc

      # 開始時刻を決定（UTCで計算）とミリ秒形式に変換
      start_time = if last_synced_at.nil? || last_synced_at < two_years_ago_utc
                     two_years_ago_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      else
                     last_synced_at.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      end

      # 終了時刻もミリ秒形式で
      end_time = current_time_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")

      Rails.logger.info "🕒 Time Range (UTC): #{start_time} to #{end_time}"
      Rails.logger.info "🕒 Time Range (JST): #{Time.parse(start_time).in_time_zone('Tokyo')} to #{Time.parse(end_time).in_time_zone('Tokyo')}"

      loop do
        # フィルター文字列を作成してURLエンコード
        filter_str = "creationdate:[#{start_time}..#{end_time}]"
        encoded_filter = URI.encode_www_form_component(filter_str)

        Rails.logger.info "📡 Raw filter: #{filter_str}"
        Rails.logger.info "📡 Encoded filter: #{encoded_filter}"

        response = client.get do |req|
          req.url API_ENDPOINT
          req.headers = auth_headers(current_user)
          req.params = {
            filter: encoded_filter,
            limit: limit,
            offset: offset
          }
        end

        orders_data = JSON.parse(response.body)
        break if orders_data["orders"].empty?

        all_orders.concat(orders_data["orders"])

        loop_count += 1
        Rails.logger.info "eBay注文取得中: #{all_orders.size}件 (#{loop_count}回目)"

        break if orders_data["orders"].size < limit
        offset += limit
      end

      # 最終同期日時を返す（UTC）
      last_synced_at = current_time_utc
      Rails.logger.info "✅ eBay注文取得完了: 合計 #{all_orders.size} 件"
      Rails.logger.info "🕒 最終同期日時 (UTC): #{last_synced_at}"
      Rails.logger.info "🕒 最終同期日時 (JST): #{last_synced_at.in_time_zone('Tokyo')}"

      { orders: all_orders, last_synced_at: last_synced_at }
    rescue Faraday::BadRequestError, Faraday::UnauthorizedError, Faraday::ForbiddenError => e
      error_body = e.response[:body] rescue nil
      Rails.logger.error "eBay API Error: #{error_body}"
      Rails.logger.error "Status: #{e.response[:status]}"
      raise FulfillmentError, "受注情報取得エラー (#{e.response[:status]}): #{error_body}"
    rescue Faraday::Error => e
      error_body = e.response[:body] rescue nil
      Rails.logger.error "eBay API Error: #{error_body}"
      Rails.logger.error "Status: #{e.response[:status]}"
      raise FulfillmentError, "受注情報取得エラー: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Unexpected Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def validate_auth_token
      token = @auth_service.access_token
      Rails.logger.debug "validate_auth_token called. token: #{token.present? ? 'present' : 'nil'}" # トークン検証ログ
      raise FulfillmentError, "アクセストークンの取得に失敗しました" if token.nil?
      token
    end

    def client
      @client ||= Faraday.new(url: "https://api.ebay.com") do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        # デバッグログを有効化
        faraday.response :logger, Rails.logger, bodies: true
      end
    end

    def auth_headers(current_user)
      {
        "Authorization" => "Bearer #{validate_auth_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end
  end
end
