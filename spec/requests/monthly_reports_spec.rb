# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "MonthlyReports", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /monthly_reports" do
    context "認証済みユーザーの場合" do
      before do
        # テストデータの作成
        # 2023年のデータ
        create_orders_for_year(user, 2023)

        # 2022年のデータ
        create_orders_for_year(user, 2022)
      end

      def create_orders_for_year(user, year)
        (1..12).each do |month|
          date = Date.new(year, month, 15)
          # 月ごとに3件の注文を作成
          3.times do |i|
            order = create(:order,
              user: user,
              sale_date: date,
              order_number: "#{year}#{month}#{i}"
            )

            # 売上データを作成
            create(:sale,
              order: order,
              order_net_amount: 100000 * (month * 0.1)
            )

            # 原価データを作成
            create(:procurement,
              order: order,
              purchase_price: 50000 * (month * 0.1),
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
        expect(assigns(:selected_year)).to eq(Time.current.year)
        expect(assigns(:monthly_data).size).to eq(12)
        expect(assigns(:monthly_data).first[:month]).to eq(1)
        expect(assigns(:monthly_data).last[:month]).to eq(12)
      end

      context "年度パラメータがある場合" do
        it "指定された年度のデータを表示すること" do
          get monthly_reports_path, params: { year: 2022 }
          expect(assigns(:selected_year)).to eq(2022)
          # 一月のデータを確認
          expect(assigns(:monthly_data)[0][:revenue]).to be > 0
        end
      end

      it "利用可能な年度リストを取得すること" do
        get monthly_reports_path
        expect(assigns(:available_years)).to include(2022, 2023)
      end

      it "月次集計が正しく行われること" do
        get monthly_reports_path, params: { year: 2023 }

        # 各月のデータをチェック
        monthly_data = assigns(:monthly_data)
        expect(monthly_data).to be_present

        # データが12ヶ月分あること
        expect(monthly_data.size).to eq(12)

        # 各メトリクスが計算されていること
        january_data = monthly_data.find { |d| d[:month] == 1 }
        expect(january_data[:revenue]).to be_present
        expect(january_data[:procurement_cost]).to be_present
        expect(january_data[:gross_profit]).to be_present
        expect(january_data[:expenses]).to be_present
        expect(january_data[:contribution_margin]).to be_present
        expect(january_data[:contribution_margin_rate]).to be_present

        # 粗利の計算が正しいこと
        expect(january_data[:gross_profit]).to eq(january_data[:revenue] - january_data[:procurement_cost])

        # 限界利益の計算が正しいこと
        expect(january_data[:contribution_margin]).to eq(january_data[:gross_profit] - january_data[:expenses])
      end
    end

    context "未認証ユーザーの場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトすること" do
        get monthly_reports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
