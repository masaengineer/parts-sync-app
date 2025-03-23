require 'rails_helper'

RSpec.describe Ebay::SellerFeeTransactionImporter do
  let(:mock_api_client) { instance_double(Ebay::EbayFinanceClient) }
  let(:importer) { described_class.new(mock_api_client) }
  let(:transactions_data) { { 'transactions' => [] } }
  let(:users) { instance_double('ActiveRecord::Relation', pluck: [1, 2]) }

  before do
    allow(mock_api_client).to receive(:fetch_transactions).and_return(transactions_data)
  end

  describe '#import' do
    it 'APIからトランザクションを取得する' do
      importer.import(users)
      expect(mock_api_client).to have_received(:fetch_transactions)
    end

    context 'トランザクションが存在しない場合' do
      it '処理完了メッセージを返す' do
        expect(importer.import(users)).to eq('処理が完了しました')
      end
    end

    context 'トランザクションが存在する場合' do
      let(:order) { instance_double('Order', id: 1, order_number: '123456789') }
      let(:transactions_data) do
        {
          'transactions' => [
            {
              'transactionId' => 'tx1',
              'transactionType' => 'SALE',
              'orderId' => '123456789',
              'amount' => { 'value' => '10.00' },
              'totalFeeBasisAmount' => { 'value' => '12.00' },
              'orderLineItems' => [
                {
                  'marketplaceFees' => [
                    { 'feeType' => 'INSERTION', 'amount' => { 'value' => '0.35' } }
                  ]
                }
              ]
            }
          ]
        }
      end

      it '対応するトランザクション処理クラスを呼び出す' do
        allow(Order).to receive(:joins).with(:user).and_return(Order)
        allow(Order).to receive(:where).with(users: { id: users.pluck(:id) }).and_return(Order)
        allow(Order).to receive(:find_by).with(order_number: '123456789').and_return(order)

        processor = instance_double(Ebay::Transactions::SaleTransactionProcessor)
        allow(Ebay::Transactions::SaleTransactionProcessor).to receive(:new).with(order, transactions_data['transactions'][0]).and_return(processor)
        expect(processor).to receive(:process).and_return(true)

        importer.import(users)
      end
    end

    context 'NON_SALE_CHARGEトランザクションの場合' do
      let(:order) { instance_double('Order', id: 1, order_number: '123456789') }
      let(:transactions_data) do
        {
          'transactions' => [
            {
              'transactionId' => 'tx2',
              'transactionType' => 'NON_SALE_CHARGE',
              'feeType' => 'AD_FEE',
              'references' => [
                { 'referenceType' => 'ORDER_ID', 'referenceId' => '123456789' }
              ],
              'amount' => { 'value' => '5.00' },
              'totalFeeBasisAmount' => { 'value' => '5.00' },
              'bookingEntry' => 'DEBIT'
            }
          ]
        }
      end

      it '対応するトランザクション処理クラスを呼び出す' do
        allow(Order).to receive(:joins).with(:user).and_return(Order)
        allow(Order).to receive(:where).with(users: { id: users.pluck(:id) }).and_return(Order)
        allow(Order).to receive(:find_by).with(order_number: '123456789').and_return(order)

        processor = instance_double(Ebay::Transactions::NonSaleChargeTransactionProcessor)
        allow(Ebay::Transactions::NonSaleChargeTransactionProcessor).to receive(:new).with(order, transactions_data['transactions'][0]).and_return(processor)
        expect(processor).to receive(:process).and_return(true)

        importer.import(users)
      end
    end

    context '未対応のトランザクションタイプの場合' do
      let(:transactions_data) do
        {
          'transactions' => [
            {
              'transactionId' => 'tx3',
              'transactionType' => 'UNKNOWN_TYPE',
              'orderId' => '123456789'
            }
          ]
        }
      end

      it 'ログにメッセージを出力する' do
        allow(Order).to receive(:joins).with(:user).and_return(Order)
        allow(Order).to receive(:where).with(users: { id: users.pluck(:id) }).and_return(Order)
        allow(Order).to receive(:find_by).and_return(instance_double('Order', id: 1))
        allow(Rails.logger).to receive(:debug).with(any_args)
        expect(Rails.logger).to receive(:debug).with(/Unsupported transaction type/).at_least(:once)

        importer.import(users)
      end
    end

    context 'APIエラーが発生した場合' do
      before do
        allow(mock_api_client).to receive(:fetch_transactions).and_raise(Ebay::EbayFinanceClient::FinanceError.new('API error'))
      end

      it '例外をスローする' do
        expect { importer.import(users) }.to raise_error(Ebay::SellerFeeTransactionImporter::ImportError, /取引データのインポートに失敗しました: API error/)
      end
    end
  end

  describe '#find_order_number' do
    context 'NON_SALE_CHARGEトランザクションの場合' do
      let(:transaction) do
        {
          'transactionType' => 'NON_SALE_CHARGE',
          'references' => [
            { 'referenceType' => 'ORDER_ID', 'referenceId' => '123456789' }
          ]
        }
      end

      it 'referencesからorder_idを取得する' do
        expect(importer.send(:find_order_number, transaction)).to eq('123456789')
      end
    end

    context '通常のトランザクションの場合' do
      let(:transaction) do
        {
          'transactionType' => 'SALE',
          'orderId' => '123456789'
        }
      end

      it 'orderIdを直接取得する' do
        expect(importer.send(:find_order_number, transaction)).to eq('123456789')
      end
    end

    context '無効な注文番号の場合' do
      let(:transaction) do
        {
          'transactionType' => 'SALE',
          'orderId' => '0'
        }
      end

      it 'nilを返す' do
        expect(importer.send(:find_order_number, transaction)).to be_nil
      end
    end
  end
end
