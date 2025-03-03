# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user, first_name: "太郎", last_name: "山田", email: "taro@example.com") }

  before do
    sign_in user
  end

  describe "GET /users" do
    it "redirects to edit user path" do
      get users_path
      # ユーザー詳細ページにリダイレクトすると期待
      expect(response).to redirect_to(user_path(user))
    end
  end

  describe "GET /users/:id" do
    it "returns a successful response" do
      get user_path(user)
      expect(response).to be_successful
    end
  end

  # edit, updateアクションはルーティングにないため、テストを削除

  context "when user is not authenticated" do
    before do
      sign_out user
    end

    it "redirects to login page" do
      get users_path
      expect(response).to redirect_to(new_user_session_path)

      get user_path(user)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
