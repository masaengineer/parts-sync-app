module Ebay
  class EbaySalesOrderClient
    class FulfillmentError < StandardError; end

    API_ENDPOINT = "/sell/fulfillment/v1/order".freeze

    def initialize
      @auth_service = EbayAuthClient.new
      validate_auth_token
    end

    def fetch_orders(current_user)
      all_orders = []
      offset = 0
      limit = 200
      loop_count = 0

      current_time_utc = Time.now.utc
      two_years_ago_utc = (current_time_utc - 18.months + 1.day)

      last_synced_at = current_user.ebay_orders_last_synced_at&.utc

      start_time = if last_synced_at.nil? || last_synced_at < two_years_ago_utc
                    two_years_ago_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      else
                    last_synced_at.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      end

      end_time = current_time_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")

      loop do
        filter_str = "creationdate:[#{start_time}..#{end_time}]"
        encoded_filter = URI.encode_www_form_component(filter_str)

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

        break if orders_data["orders"].size < limit
        offset += limit
      end

      last_synced_at = current_time_utc

      { orders: all_orders, last_synced_at: last_synced_at }
    rescue Faraday::BadRequestError, Faraday::UnauthorizedError, Faraday::ForbiddenError => e
      error_body = e.response[:body] rescue nil
      raise FulfillmentError, "受注情報取得エラー (#{e.response[:status]}): #{error_body}"
    rescue Faraday::Error => e
      error_body = e.response[:body] rescue nil
      raise FulfillmentError, "受注情報取得エラー: #{e.message}"
    rescue StandardError => e
      raise FulfillmentError, "予期せぬエラーが発生しました: #{e.message}"
    end

    private

    def validate_auth_token
      token = @auth_service.access_token
      raise FulfillmentError, "アクセストークンの取得に失敗しました" if token.nil?
      token
    end

    def client
      @client ||= Faraday.new(url: "https://api.ebay.com") do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
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
