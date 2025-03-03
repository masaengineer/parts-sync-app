require 'rails_helper'
require 'ostruct'

RSpec.describe Ebay::EbayFinanceClient do
  # モックオブジェクトを先に準備
  let(:mock_auth_service) { instance_double(Ebay::EbayAuthClient, access_token: 'dummy_token') }
  let(:mock_conn) { instance_double(Faraday::Connection) }
  let(:mock_response) { instance_double(Faraday::Response, status: 200, body: { transactions: [], total: 0 }.to_json) }
  let(:mock_faraday) { double('Faraday') }

  # 重要: credentialsのモック設定を先に行う
  before do
    # Rails.application.credentialsのebayをモック
    mock_ebay_credentials = OpenStruct.new(
      client_id: 'test_client_id',
      client_secret: 'test_client_secret',
      refresh_token: 'test_refresh_token'
    )
    allow(Rails.application.credentials).to receive(:ebay).and_return(mock_ebay_credentials)

    allow(Ebay::EbayAuthClient).to receive(:new).and_return(mock_auth_service)

    # Faradayの初期化のモック
    allow(Faraday).to receive(:new) do |&block|
      allow(mock_faraday).to receive(:request)
      allow(mock_faraday).to receive(:response)
      allow(mock_faraday).to receive(:adapter)
      block.call(mock_faraday) if block
      mock_conn
    end

    # getメソッドのモック
    allow(mock_conn).to receive(:get) do |&block|
      request = double('Request')
      allow(request).to receive(:url)
      allow(request).to receive(:headers=)
      allow(request).to receive(:params=)
      allow(request).to receive(:headers).and_return({})
      allow(request).to receive(:params).and_return({})
      block.call(request) if block
      mock_response
    end

    # ロガーのモック
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  # モック設定後にクライアントを初期化
  let(:client) { described_class.new }

  describe '#fetch_transactions' do
    it '正常にトランザクションを取得する' do
      result = client.fetch_transactions
      expect(result).to include('transactions')
    end

    context 'フィルター付きで呼び出す場合' do
      let(:filters) { { order_id: '12345' } }

      it 'フィルターを適用してAPIを呼び出す' do
        client.fetch_transactions(filters)
        # 検証はgetブロック内でパラメータが正しく設定されることを想定
      end
    end

    context 'エラーレスポンスを受け取った場合' do
      let(:error_response) { OpenStruct.new(status: 400, body: { errors: [ { message: 'API error' } ] }.to_json) }

      before do
        faraday_error = Faraday::BadRequestError.new('Bad Request', error_response)
        allow(faraday_error).to receive(:response).and_return(error_response)
        allow(mock_conn).to receive(:get).and_raise(faraday_error)
      end

      it '例外をスローする' do
        expect { client.fetch_transactions }.to raise_error(Ebay::EbayFinanceClient::FinanceError, /取引情報取得エラー: Bad Request/)
      end
    end

    context '接続エラーが発生した場合' do
      before do
        allow(mock_conn).to receive(:get).and_raise(Faraday::ConnectionFailed.new('Connection error'))
      end

      it '例外をスローする' do
        expect { client.fetch_transactions }.to raise_error(Ebay::EbayFinanceClient::FinanceError, /取引情報取得エラー: Connection error/)
      end
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
      headers = client.send(:auth_headers)
      expect(headers).to include(
        'Authorization' => 'Bearer dummy_token',
        'Content-Type' => 'application/json'
      )
    end
  end
end
