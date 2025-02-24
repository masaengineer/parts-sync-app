# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "SalesReports", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /sales_reports" do
    context "with authenticated user" do
      before do
        # テストデータの作成
        3.times do
          order = create(:order, user: user, sale_date: Time.current)
          create(:sale, order: order, order_net_amount: 100.0)
          create(:payment_fee, order: order, fee_amount: 10.0)
          create(:shipment, order: order, customer_international_shipping: 2000)
          create(:procurement,
            order: order,
            purchase_price: 5000,
            forwarding_fee: 500,
            option_fee: 300,
            handling_fee: 200
          )
          seller_sku = create(:seller_sku, sku_code: "SKU#{order.id}")
          create(:order_line,
            order: order,
            seller_sku: seller_sku,
            quantity: 2,
            line_item_name: "商品#{order.id}"
          )
        end
      end

      it "returns a successful response" do
        get sales_reports_path
        expect(response).to be_successful
      end

      it "displays correct number of orders" do
        get sales_reports_path
        expect(assigns(:orders).count).to eq(3)
      end

      context "with search parameters" do
        let!(:target_order) do
          order = create(:order,
            user: user,
            sale_date: Time.current - 1.day,
            order_number: "TEST123"
          )
          create(:sale, order: order, order_net_amount: 100.0)
          order
        end

        it "filters by order number" do
          get sales_reports_path, params: { q: { order_number_eq: "TEST123" } }
          expect(assigns(:orders).count).to eq(1)
          expect(assigns(:orders).first).to eq(target_order)
        end

        it "filters by date range" do
          get sales_reports_path, params: {
            q: {
              sale_date_gteq: (Time.current - 2.days).to_date,
              sale_date_lteq: Time.current.to_date
            }
          }
          expect(assigns(:orders)).to include(target_order)
        end
      end

      context "with pagination" do
        before do
          # さらに7件のオーダーを追加（合計10件）
          7.times do
            create(:order, user: user, sale_date: Time.current)
          end
        end

        it "respects per_page parameter" do
          get sales_reports_path, params: { per_page: 5 }
          expect(assigns(:orders).count).to eq(5)
        end

        it "uses default per_page value" do
          get sales_reports_path
          expect(assigns(:orders).count).to eq(10) # デフォルトは30なので全件表示される
        end
      end
    end

    context "with unauthenticated user" do
      before do
        sign_out user
      end

      it "redirects to login page" do
        get sales_reports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
