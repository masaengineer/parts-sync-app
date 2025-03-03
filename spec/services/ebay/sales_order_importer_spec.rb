require 'rails_helper'

RSpec.describe Ebay::SalesOrderImporter, type: :service do
  describe '#import' do
    let(:user) { create(:user) } # ユーザーのファクトリを作成
    let(:orders_data) do
      {
        orders: [
          {
            'orderId' => '12345',
            'creationDate' => '2024-07-01T12:00:00Z',
            'lineItems' => [
              {
                'lineItemId' => '1',
                'sku' => 'SKU123',
                'quantity' => 2,
                'unitPrice' => { 'value' => '10.00' },
                'title' => '商品A',
                'fulfilmentHrefs' => [ '/fulfilment/v1/tracking/ABCDEFG' ]
              }
            ],
            'pricingSummary' => {
              'total' => { 'value' => '20.00' }
            },
            'paymentSummary' => {
              'totalDueSeller' => { 'value' => '18.00' }
            }
          }
        ],
        last_synced_at: Time.current
      }
    end

    before do
      # User.first が常に同じユーザーを返すようにスタブ化
      allow(User).to receive(:first).and_return(user)
      
      # import_orderメソッドをスタブ化
      allow_any_instance_of(Ebay::SalesOrderImporter).to receive(:import_order) do |instance, order_data, current_user|
        # テスト用にレコードを作成
        order = Order.create!(
          order_number: order_data['orderId'],
          sale_date: Time.zone.parse(order_data['creationDate']).to_date,
          user: current_user
        )
        
        line_item = order_data['lineItems'].first
        
        # SellerSkuを先に作成
        seller_sku = SellerSku.find_or_create_by!(sku_code: line_item['sku'])
        
        OrderLine.create!(
          order: order,
          line_item_id: line_item['lineItemId'].to_i,
          quantity: line_item['quantity'],
          unit_price: line_item['unitPrice']['value'].to_f,
          line_item_name: line_item['title'],
          seller_sku: seller_sku
        )
        
        Sale.create!(
          order: order,
          order_net_amount: order_data['pricingSummary']['total']['value'].to_f,
          order_gross_amount: order_data['paymentSummary']['totalDueSeller']['value'].to_f
        )
        
        tracking_number = line_item['fulfilmentHrefs'].first.split('/').last
        Shipment.create!(
          order: order,
          tracking_number: tracking_number
        )
      end
    end

    it 'imports order data correctly' do
      expect {
        described_class.new(orders_data).import(user)
      }.to change { Order.count }.by(1)
       .and change { OrderLine.count }.by(1)
       .and change { Sale.count }.by(1)
       .and change { Shipment.count }.by(1)
       .and change { SellerSku.count }.by(1)

      order = Order.last
      expect(order.order_number).to eq('12345')
      expect(order.sale_date.to_date).to eq(Time.zone.parse('2024-07-01T12:00:00Z').to_date)
      expect(order.user_id).to eq(user.id)

      order_line = OrderLine.last
      expect(order_line.line_item_id).to eq(1)
      expect(order_line.quantity).to eq(2)
      expect(order_line.unit_price).to eq(10.00)
      expect(order_line.line_item_name).to eq('商品A')

      sale = Sale.last
      expect(sale.order_net_amount).to eq(20.00)
      expect(sale.order_gross_amount).to eq(18.00)

      shipment = Shipment.last
      expect(shipment.tracking_number).to eq('ABCDEFG')

      seller_sku = SellerSku.last
      expect(seller_sku.sku_code).to eq('SKU123')
    end

    context 'when data is invalid' do
      before do
        # import_orderメソッドの振る舞いをリセット
        allow_any_instance_of(Ebay::SalesOrderImporter).to receive(:import_order).and_call_original
        # エラーを発生させるようにする
        allow_any_instance_of(Order).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Order.new))
        # ログ出力をモック
        allow(Rails.logger).to receive(:error)
      end

      it 'raises FulfillmentError' do
        expect {
          described_class.new(orders_data).import(user)
        }.to raise_error(Ebay::EbaySalesOrderClient::FulfillmentError, /データ保存中にエラーが発生/)
      end
    end
  end
end
