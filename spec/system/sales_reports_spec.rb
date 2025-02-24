# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "SalesReports", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  describe 'index page' do
    context 'with sales data' do
      before do
        # テストデータの作成
        3.times do |i|
          order = create(:order,
            user: user,
            sale_date: Time.current - i.days,
            order_number: "ORDER#{i+1}"
          )
          create(:sale, order: order, order_net_amount: 100.0 * (i+1))
          create(:payment_fee, order: order, fee_amount: 10.0)
          create(:shipment, order: order, customer_international_shipping: 2000)
          create(:procurement,
            order: order,
            purchase_price: 5000,
            forwarding_fee: 500,
            option_fee: 300,
            handling_fee: 200
          )
          seller_sku = create(:seller_sku, sku_code: "SKU#{i+1}")
          create(:order_line,
            order: order,
            seller_sku: seller_sku,
            quantity: 2,
            line_item_name: "商品#{i+1}"
          )
        end
        visit sales_reports_path
      end

      it 'displays the sales report table' do
        expect(page).to have_selector('#order_table')
        expect(page).to have_content('ORDER1')
        expect(page).to have_content('ORDER2')
        expect(page).to have_content('ORDER3')
      end

      it 'allows filtering by order number' do
        within('#order_filter') do
          fill_in '注文番号', with: 'ORDER1'
          click_button '検索'
        end

        expect(page).to have_content('ORDER1')
        expect(page).not_to have_content('ORDER2')
        expect(page).not_to have_content('ORDER3')
      end

      it 'allows filtering by date range' do
        within('#order_filter') do
          fill_in '販売日（開始）', with: Time.current.yesterday.strftime('%Y-%m-%d')
          fill_in '販売日（終了）', with: Time.current.strftime('%Y-%m-%d')
          click_button '検索'
        end

        expect(page).to have_content('ORDER1')
        expect(page).to have_content('ORDER2')
        expect(page).not_to have_content('ORDER3')
      end

      it 'allows changing the number of items per page' do
        within('.card-body') do
          select '10', from: 'per_page'
        end
        
        expect(current_url).to include('per_page=10')
      end

      it 'allows resetting search filters' do
        # まず検索を実行
        within('#order_filter') do
          fill_in '注文番号', with: 'ORDER1'
          click_button '検索'
        end
        expect(page).not_to have_content('ORDER2')

        # リセットボタンをクリック
        click_link 'リセット'
        
        # すべての結果が表示されることを確認
        expect(page).to have_content('ORDER1')
        expect(page).to have_content('ORDER2')
        expect(page).to have_content('ORDER3')
      end

      it 'shows loading state while searching', js: true do
        within('#order_filter') do
          fill_in '注文番号', with: 'ORDER1'
          click_button '検索'
        end

        # ローディングスピナーの表示を確認
        expect(page).to have_selector('.loading-spinner')
      end
    end

    context 'with no sales data' do
      before do
        visit sales_reports_path
      end

      it 'displays an empty state message' do
        expect(page).to have_content('データがありません')
      end
    end
  end
end
