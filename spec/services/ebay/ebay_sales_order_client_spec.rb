require 'rails_helper'
require 'ostruct'

RSpec.describe Ebay::EbaySalesOrderClient do
  let(:client) { described_class.new }
  let(:mock_auth_service) { instance_double(Ebay::EbayAuthClient, access_token: 'dummy_token') }
  let(:mock_conn) { instance_double(Faraday::Connection) }
  let(:mock_faraday) { double('Faraday') }
  let(:current_user) { instance_double('User', ebay_orders_last_synced_at: nil) }

  before do
    allow(Ebay::EbayAuthClient).to receive(:new).and_return(mock_auth_service)

    # Faradayの初期化のモック
    allow(Faraday).to receive(:new) do |&block|
      allow(mock_faraday).to receive(:request)
      allow(mock_faraday).to receive(:response)
      allow(mock_faraday).to receive(:adapter)
      block.call(mock_faraday) if block
      mock_conn
    end

    # validate_auth_tokenが呼ばれた時のを確実に値を返すように
    allow_any_instance_of(described_class).to receive(:validate_auth_token).and_return('dummy_token')
  end

  describe '#fetch_orders' do
    let(:orders_response) do
      instance_double(
        Faraday::Response,
        status: 200,
        body: {
          orders: [ { orderId: '12345' } ],
          total: 1
        }.to_json
      )
    end

    before do
      # getメソッドのモック
      allow(mock_conn).to receive(:get) do |&block|
        request = double('Request')
        allow(request).to receive(:url)
        allow(request).to receive(:headers=)
        allow(request).to receive(:params=)
        allow(request).to receive(:headers).and_return({})
        allow(request).to receive(:params).and_return({})
        block.call(request) if block
        orders_response
      end
    end

    it '全ての注文データを取得する' do
      result = client.fetch_orders(current_user)
      expect(result[:orders].size).to eq(1)
      expect(result[:orders][0]["orderId"]).to eq("12345")
    end

    context 'APIエラーが発生した場合' do
      let(:error_response) { { status: 401, body: { errors: [ { message: 'Unauthorized' } ] }.to_json } }

      before do
        allow(mock_conn).to receive(:get).and_raise(
          Faraday::UnauthorizedError.new(response: error_response)
        )
      end

      it '例外をスローする' do
        expect { client.fetch_orders(current_user) }.to raise_error(Ebay::EbaySalesOrderClient::FulfillmentError, /受注情報取得エラー/)
      end
    end

    context '接続エラーが発生した場合' do
      before do
        allow(mock_conn).to receive(:get).and_raise(Faraday::ConnectionFailed.new('Connection error'))
      end

      it '例外をスローする' do
        expect { client.fetch_orders(current_user) }.to raise_error(Ebay::EbaySalesOrderClient::FulfillmentError, /受注情報取得エラー: Connection error/)
      end
    end
  end

  describe '#validate_auth_token' do
    before do
      # クラスのインスタンス化時に呼ばれるvalidate_auth_tokenをオーバーライドせずに、テストだけ実行できるように
      allow_any_instance_of(described_class).to receive(:validate_auth_token).and_call_original
    end

    it '有効なトークンを検証する' do
      token = client.send(:validate_auth_token)
      expect(token).to eq('dummy_token')
    end
  end

  describe '#client' do
    it 'Faradayクライアントを初期化する' do
      client.send(:client)
      expect(Faraday).to have_received(:new)
    end
  end

  describe '#auth_headers' do
    it '認証ヘッダーを返す' do
      headers = client.send(:auth_headers, current_user)
      expect(headers).to include('Authorization' => 'Bearer dummy_token')
    end
  end

# 以下のテストは実装に存在しないメソッドなのでスキップまたはコメントアウト
=begin
  describe '#extract_order_data' do
    let(:order_data) do
      {
        'orders' => [
          { 'orderId' => '12345' },
          { 'orderId' => '67890' }
        ]
      }
    end

    it '注文データを抽出する' do
      extracted = client.send(:extract_order_data, order_data.to_json)
      expect(extracted).to eq(order_data['orders'])
    end

    context 'JSONが無効な場合' do
      it '空の配列を返す' do
        extracted = client.send(:extract_order_data, 'invalid json')
        expect(extracted).to eq([])
      end
    end
  end

  describe '#next_page_url' do
    let(:response_body) do
      {
        'next' => 'https://api.ebay.com/next-page'
      }.to_json
    end

    it '次のページURLを抽出する' do
      next_url = client.send(:next_page_url, response_body)
      expect(next_url).to eq('https://api.ebay.com/next-page')
    end

    context '次のページがない場合' do
      let(:response_body) do
        {
          'orders' => []
        }.to_json
      end

      it 'nilを返す' do
        next_url = client.send(:next_page_url, response_body)
        expect(next_url).to be_nil
      end
    end
  end
=end
end
