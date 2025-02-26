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
      expect(response).to redirect_to(edit_user_path(user))
    end
  end

  describe "GET /users/:id" do
    it "returns a successful response" do
      get user_path(user)
      expect(response).to be_successful
    end
  end

  describe "GET /users/:id/edit" do
    it "returns a successful response" do
      get edit_user_path(user)
      expect(response).to be_successful
    end
  end

  describe "PATCH /users/:id" do
    context "with valid parameters" do
      let(:valid_attributes) do
        { user: { first_name: "次郎", last_name: "鈴木", email: "jiro@example.com" } }
      end

      it "updates the user and redirects" do
        patch user_path(user), params: valid_attributes

        expect(response).to redirect_to(edit_user_path(user))
        expect(flash[:notice]).to be_present

        # ユーザー情報が更新されたことを確認
        user.reload
        expect(user.first_name).to eq("次郎")
        expect(user.last_name).to eq("鈴木")
        expect(user.email).to eq("jiro@example.com")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { user: { email: "invalid-email" } }
      end

      it "does not update the user and returns unprocessable entity status" do
        patch user_path(user), params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)

        # ユーザー情報が更新されていないことを確認
        user.reload
        expect(user.email).to eq("taro@example.com")
      end
    end
  end

  context "when user is not authenticated" do
    before do
      sign_out user
    end

    it "redirects to login page" do
      get users_path
      expect(response).to redirect_to(new_user_session_path)

      get user_path(user)
      expect(response).to redirect_to(new_user_session_path)

      get edit_user_path(user)
      expect(response).to redirect_to(new_user_session_path)

      patch user_path(user), params: { user: { first_name: "New Name" } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
