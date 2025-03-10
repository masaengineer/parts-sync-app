# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyReportsController, type: :request do
  let(:user) { create(:user) }
  # 現在の年度を取得
  let(:current_year) { Time.current.year }
  # テスト用通貨を作成
  let!(:usd_currency) {
    Currency.find_by(code: 'USD') || create(:currency, :usd)
  }

  before do
    sign_in user
    # CSRFトークンを無効化して、認証エラーを回避
    allow_any_instance_of(ActionController::Base).to receive(:protect_against_forgery?).and_return(false)
    # 認証をバイパス
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    context "認証済みユーザーの場合" do
      before do
        # テストデータの作成
        # 2023年のデータ
        create_orders_for_year(user, 2023)

        # 2022年のデータ
        create_orders_for_year(user, 2022)

        # 現在年のデータも作成
        create_orders_for_year(user, current_year)
      end

      def create_orders_for_year(user, year)
        (1..12).each do |month|
          date = Date.new(year, month, 15)
          # 月ごとに3件の注文を作成
          3.times do |i|
            order = create(:order,
              user: user,
              sale_date: date,
              order_number: "#{year}#{month}#{i}",
              currency: usd_currency
            )

            # 売上データを作成 - 2月以降は額を大きくする
            amount = month >= 2 ? 100000 * (month * 0.1) : 1000
            create(:sale,
              order: order,
              order_net_amount: amount,
              to_usd_rate: 1.0
            )

            # 原価データを作成
            create(:procurement,
              order: order,
              purchase_price: amount * 0.5, # 売上の半分を原価とする
              forwarding_fee: 5000,
              option_fee: 2000,
              handling_fee: 3000
            )

            # 販管費を作成（月ごとに1件）
            if i == 0
              create(:expense,
                year: year,
                month: month,
                item_name: "月次経費",
                amount: 20000 * (month * 0.1)
              )
            end
          end
        end
      end

      it "成功レスポンスを返すこと" do
        get monthly_reports_path
        expect(response).to be_successful
      end

      it "デフォルトで今年のデータを表示すること" do
        get monthly_reports_path
        expect(response).to be_successful
        expect(response.body).to include(current_year.to_s)
      end

      context "年度パラメータがある場合" do
        it "指定された年度のデータを表示すること" do
          get monthly_reports_path, params: { year: current_year - 1 }
          expect(response).to be_successful
          expect(response.body).to include((current_year - 1).to_s)
        end
      end

      it "利用可能な年度リストを取得すること" do
        # テストで作成した2022年と2023年のデータがあること
        get monthly_reports_path
        expect(response).to be_successful
        expect(response.body).to include('2022')
        expect(response.body).to include('2023')
      end

      it "テーブルが表示されること" do
        get monthly_reports_path
        expect(response).to be_successful
        # テーブルが表示されることを確認
        expect(response.body).to include('<table')
        expect(response.body).to include('</table>')
      end
    end

    context "未認証ユーザーの場合" do
      before do
        sign_out user
        # 認証バイパスを解除
        allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_call_original
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_call_original
      end

      it "ログインページにリダイレクトすること" do
        get monthly_reports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
