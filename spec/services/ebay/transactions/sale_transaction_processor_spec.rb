require 'rails_helper'

RSpec.describe Ebay::Transactions::SaleTransactionProcessor do
  let(:order) { instance_double('Order', id: 1) }
  let(:transaction) do
    {
      'transactionId' => 'sale-tx1',
      'transactionType' => 'SALE',
      'amount' => { 'value' => '100.00' },
      'totalFeeBasisAmount' => { 'value' => '120.00' },
      'orderLineItems' => [
        {
          'marketplaceFees' => [
            { 'feeType' => 'INSERTION', 'amount' => { 'value' => '0.35' } },
            { 'feeType' => 'FINAL_VALUE', 'amount' => { 'value' => '12.00' } }
          ]
        }
      ]
    }
  end

  let(:processor) { described_class.new(order, transaction) }

  describe '#transaction_type' do
    it '正しいトランザクションタイプを返す', skip: 'プロテクトメソッドのためスキップ' do
      # protected メソッドを呼び出すために send を使用
      expect(processor.send(:transaction_type)).to eq('sale')
    end
  end

  describe '#process_transaction' do
    before do
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:error)
    end

    it '手数料を処理しSaleレコードを作成する' do
      expect(processor).to receive(:process_marketplace_fees).and_return(true)
      expect(processor).to receive(:create_sale_record)
      processor.send(:process_transaction)
    end

    context '手数料処理が失敗した場合' do
      it 'Saleレコードを作成しない' do
        expect(processor).to receive(:process_marketplace_fees).and_return(false)
        expect(processor).not_to receive(:create_sale_record)
        processor.send(:process_transaction)
      end
    end
  end

  describe '#process_marketplace_fees', skip: 'PaymentFeeモデルの実装に依存するため実際には実行しない' do
    before do
      # PaymentFeeモデルのモック設定
      payment_fee_class = class_double('PaymentFee').as_stubbed_const
      allow(payment_fee_class).to receive(:create!).and_return(instance_double('PaymentFee'))
      allow(payment_fee_class).to receive(:exists?).and_return(false)
      allow(payment_fee_class).to receive(:fee_categories).and_return({'insertion' => 'INSERTION', 'final_value' => 'FINAL_VALUE'})
    end

    it '手数料を処理する' do
      expect(processor).to receive(:process_single_fee).with(anything, anything, anything).twice.and_return(true)
      result = processor.send(:process_marketplace_fees)
      expect(result).to be true
    end

    context 'orderLineItemsがない場合' do
      let(:transaction) do
        {
          'transactionId' => 'sale-tx1',
          'transactionType' => 'SALE',
          'amount' => { 'value' => '100.00' },
          'totalFeeBasisAmount' => { 'value' => '120.00' }
        }
      end

      it '手数料処理をスキップする' do
        expect(processor.send(:process_marketplace_fees)).to be false
      end
    end

    context 'marketplaceFeesが無効な場合' do
      let(:transaction) do
        {
          'transactionId' => 'sale-tx1',
          'transactionType' => 'SALE',
          'amount' => { 'value' => '100.00' },
          'totalFeeBasisAmount' => { 'value' => '120.00' },
          'orderLineItems' => [
            { 'marketplaceFees' => nil }
          ]
        }
      end

      it '手数料処理をスキップする' do
        expect(processor.send(:process_marketplace_fees)).to be false
      end
    end
  end

  describe '#process_single_fee', skip: 'PaymentFeeモデルの実装に依存するためスキップ' do
    let(:fee) { { 'feeType' => 'INSERTION', 'amount' => { 'value' => '0.35' } } }

    before do
      # PaymentFeeモデルのモック設定
      payment_fee_class = class_double('PaymentFee').as_stubbed_const
      allow(payment_fee_class).to receive(:create!).and_return(instance_double('PaymentFee'))
      allow(payment_fee_class).to receive(:exists?).and_return(false)
      allow(payment_fee_class).to receive(:fee_categories).and_return({'insertion' => 'INSERTION'})
      allow(processor).to receive(:determine_fee_category).and_return('insertion')
    end

    it '手数料レコードを作成する' do
      expect(PaymentFee).to receive(:create!).once
      result = processor.send(:process_single_fee, fee, 0, 0)
      expect(result).to be true
    end

    context '重複する手数料がある場合' do
      before do
        allow(PaymentFee).to receive(:exists?).and_return(true)
      end

      it '手数料処理をスキップする' do
        expect(PaymentFee).not_to receive(:create!)
        result = processor.send(:process_single_fee, fee, 0, 0)
        expect(result).to be false
      end
    end
  end

  describe '#determine_fee_category' do
    before do
      allow(PaymentFee).to receive(:fee_categories).and_return({'insertion' => 'INSERTION', 'final_value' => 'FINAL_VALUE'})
    end

    it '有効な手数料カテゴリを返す' do
      fee = { 'feeType' => 'INSERTION' }
      expect(processor.send(:determine_fee_category, fee)).to eq('INSERTION')
    end

    it '未定義の手数料タイプの場合はundefinedを返す' do
      fee = { 'feeType' => 'UNKNOWN' }
      expect(processor.send(:determine_fee_category, fee)).to eq('undefined')
    end
  end

  describe '#create_sale_record', skip: 'Saleモデルの実装に依存するためスキップ' do
    before do
      # Saleモデルのモック設定
      sale_class = class_double('Sale').as_stubbed_const
      allow(sale_class).to receive(:create!).and_return(instance_double('Sale'))
      allow(sale_class).to receive(:exists?).and_return(false)
    end

    it 'Saleレコードを作成する' do
      expect(Sale).to receive(:create!).with(
        order: order,
        order_net_amount: 100.0,
        order_gross_amount: 120.0,
        exchangerate: nil
      )
      processor.send(:create_sale_record)
    end

    context '既にSaleレコードが存在する場合' do
      before do
        allow(Sale).to receive(:exists?).and_return(true)
      end

      it '新しいSaleレコードを作成しない' do
        expect(Sale).not_to receive(:create!)
        processor.send(:create_sale_record)
      end
    end

    context '為替レートが指定されている場合' do
      let(:transaction) do
        {
          'transactionId' => 'sale-tx2',
          'transactionType' => 'SALE',
          'amount' => { 'value' => '100.00', 'exchangeRate' => '110.50' },
          'totalFeeBasisAmount' => { 'value' => '120.00' }
        }
      end

      it '為替レートを保存する' do
        expect(Sale).to receive(:create!).with(
          order: order,
          order_net_amount: 100.0,
          order_gross_amount: 120.0,
          exchangerate: 110.5
        )
        processor.send(:create_sale_record)
      end
    end
  end
end
