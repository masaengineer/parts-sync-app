require 'rails_helper'

RSpec.describe Ebay::SalesOrderImporter, type: :service do
  describe '#import' do
    let(:user) { create(:user) } # ユーザーのファクトリを作成
    let(:orders_data) do
      {
        'orders' => [
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
        ]
      }
    end

    before do
      # User.first が常に同じユーザーを返すようにスタブ化
      allow(User).to receive(:first).and_return(user)
    end

    it 'imports order data correctly' do
      expect {
        described_class.new(orders_data).import
      }.to change { Order.count }.by(1)
       .and change { OrderLine.count }.by(1)
       .and change { Sale.count }.by(1)
       .and change { Shipment.count }.by(1)
       .and change { SellerSku.count }.by(1)

      order = Order.last
      expect(order.order_number).to eq('12345')
      expect(order.sale_date).to eq(Time.zone.parse('2024-07-01T12:00:00Z'))
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
        allow_any_instance_of(Order).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises FulfillmentError and logs error' do
        expect {
          described_class.new(orders_data).import
        }.to raise_error(Ebay::EbaySalesOrderClient::FulfillmentError)

        expect(Rails.logger).to receive(:error).with(/データ保存エラー/)
      end
    end
  end
end
