module Ebay
  class EbayAuthClient
    class AuthError < StandardError; end

    REQUIRED_SCOPES = [
      "https://api.ebay.com/oauth/api_scope",
      "https://api.ebay.com/oauth/api_scope/sell.fulfillment",
      "https://api.ebay.com/oauth/api_scope/sell.inventory"
    ].freeze

    def initialize
      @client_id = ENV['EBAY_CLIENT_ID'] || Rails.application.credentials.dig(:ebay, :client_id)
      @client_secret = ENV['EBAY_CLIENT_SECRET'] || Rails.application.credentials.dig(:ebay, :client_secret)
      @refresh_token = ENV['EBAY_REFRESH_TOKEN'] || Rails.application.credentials.dig(:ebay, :refresh_token)

      # 認証情報が設定されているか確認
      raise AuthError, "eBay認証情報（client_id, client_secret, refresh_token）が設定されていません" unless @client_id && @client_secret && @refresh_token

      @auth_token = nil
    end

    def access_token
      return @auth_token if @auth_token && !token_expired?

      refresh_access_token
    end

    private

    def refresh_access_token
      client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        site: "https://api.ebay.com",
        token_url: "/identity/v1/oauth2/token"
      )

      response = client.get_token(
        grant_type: "refresh_token",
        refresh_token: @refresh_token
      )

      @auth_token = response.token
      @token_expires_at = Time.now + response.expires_in

      @auth_token
    rescue OAuth2::Error => e
      Rails.logger.error "eBay OAuth Error: #{e.response.body if e.response}"
      raise AuthError, "eBay認証エラー: #{e.message}"
    end

    def token_expired?
      return true unless @token_expires_at
      Time.now >= @token_expires_at
    end
  end
end
