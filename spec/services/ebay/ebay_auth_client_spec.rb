require 'rails_helper'
require 'ostruct'

RSpec.describe Ebay::EbayAuthClient do
  # モックオブジェクトを先に準備
  let(:mock_oauth_client) { instance_double(OAuth2::Client) }
  let(:mock_access_token) { instance_double(OAuth2::AccessToken, token: 'dummy_token', expires_at: Time.now + 1.hour, expires_in: 3600) }

  # 重要: credentialsのモック設定を先に行う
  before do
    # Rails.application.credentialsのebayをモック
    mock_ebay_credentials = OpenStruct.new(
      client_id: 'test_client_id',
      client_secret: 'test_client_secret',
      refresh_token: 'test_refresh_token'
    )
    allow(Rails.application.credentials).to receive(:ebay).and_return(mock_ebay_credentials)

    allow(OAuth2::Client).to receive(:new).and_return(mock_oauth_client)
    allow(mock_oauth_client).to receive(:get_token).and_return(mock_access_token)
  end

  # モック設定後にクライアントを初期化
  let(:client) { described_class.new }

  describe '#access_token' do
    context 'トークンがキャッシュされていない場合' do
      it '新しいトークンを取得する' do
        expect(client.access_token).to eq('dummy_token')
        expect(mock_oauth_client).to have_received(:get_token)
      end
    end

    context 'トークンがキャッシュされており有効な場合' do
      it 'キャッシュされたトークンを返す' do
        # 一度目の呼び出しでトークンを取得
        client.access_token

        # トークン取得のモックをリセット
        allow(mock_oauth_client).to receive(:get_token).and_return(mock_access_token)

        # 二度目の呼び出し
        client.access_token

        # get_tokenは一度だけ呼ばれるべき
        expect(mock_oauth_client).to have_received(:get_token).once
      end
    end

    context 'トークンが期限切れの場合' do
      it '新しいトークンを取得する' do
        # 一度目の呼び出しでトークンを取得
        client.access_token

        # トークンを期限切れに設定
        client.instance_variable_set(:@token_expires_at, Time.now - 1.hour)

        # 二度目の呼び出し
        client.access_token

        # 期限切れなので新しいトークンを取得するはず
        expect(mock_oauth_client).to have_received(:get_token).twice
      end
    end
  end

  describe '#refresh_access_token' do
    it '新しいアクセストークンを取得する' do
      client.send(:refresh_access_token)
      expect(mock_oauth_client).to have_received(:get_token)
      expect(client.instance_variable_get(:@auth_token)).to eq('dummy_token')
    end

    context 'エラーが発生した場合' do
      before do
        allow(mock_oauth_client).to receive(:get_token).and_raise(OAuth2::Error.new(OpenStruct.new(status: 401, body: 'error')))
      end

      it '例外を発生させる' do
        expect { client.send(:refresh_access_token) }.to raise_error(Ebay::EbayAuthClient::AuthError)
      end
    end
  end

  describe '#token_expired?' do
    context 'トークンの有効期限が設定されていない場合' do
      it 'trueを返す' do
        client.instance_variable_set(:@token_expires_at, nil)
        expect(client.send(:token_expired?)).to be true
      end
    end

    context 'トークンの有効期限が過ぎている場合' do
      it 'trueを返す' do
        client.instance_variable_set(:@token_expires_at, Time.now - 1.hour)
        expect(client.send(:token_expired?)).to be true
      end
    end

    context 'トークンがまだ有効な場合' do
      it 'falseを返す' do
        client.instance_variable_set(:@token_expires_at, Time.now + 1.hour)
        expect(client.send(:token_expired?)).to be false
      end
    end
  end
end
