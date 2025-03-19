module Ebay
  class EbayClientFactory
    # 環境変数の名前
    MOCK_ENV_NAME = "USE_MOCK_EBAY_CLIENT"

    class << self
      # ユーザーのeBayアカウント種類に応じたEbaySalesOrderClientのインスタンスを返す
      # @param user [User] ユーザー
      # @return [EbaySalesOrderClient|MockEbaySalesOrderClient]
      def create_sales_order_client(user = nil)
        if user_uses_mock?(user)
          Rails.logger.info "#{user&.email || 'Unknown user'}のためにモックEbaySalesOrderClientを使用します"
          MockEbaySalesOrderClient.new
        else
          Rails.logger.info "#{user&.email || 'Unknown user'}のために本番EbaySalesOrderClientを使用します"
          EbaySalesOrderClient.new
        end
      end

      # ユーザーのeBayアカウント種類に応じたEbayFinanceClientのインスタンスを返す
      # @param user [User] ユーザー
      # @return [EbayFinanceClient|MockEbayFinanceClient]
      def create_finance_client(user = nil)
        if user_uses_mock?(user)
          Rails.logger.info "#{user&.email || 'Unknown user'}のためにモックEbayFinanceClientを使用します"
          MockEbayFinanceClient.new
        else
          Rails.logger.info "#{user&.email || 'Unknown user'}のために本番EbayFinanceClientを使用します"
          EbayFinanceClient.new
        end
      end

      private

      # ユーザーがモッククライアントを使用するかどうかを判定
      # @param user [User] ユーザー
      # @return [Boolean]
      def user_uses_mock?(user)
        # ユーザーが存在しない場合や、test_accountがtrueの場合はモックを使用
        user.nil? || user.test_account?
      end
    end
  end
end
