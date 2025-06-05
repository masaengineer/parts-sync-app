require 'rails_helper'

RSpec.describe "ExchangeRates", type: :request do
  let(:user) { create(:user) }
  let(:exchange_rate) { create(:exchange_rate, user: user) }

  before do
    sign_in user
  end

  describe "GET /exchange_rates" do
    it "returns http success" do
      get exchange_rates_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /exchange_rates/new" do
    it "returns http success" do
      get new_exchange_rate_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /exchange_rates" do
    context "with valid parameters" do
      it "creates a new exchange rate" do
        expect {
          post exchange_rates_path, params: {
            exchange_rate: {
              year: 2025,
              month: 1,
              usd_to_jpy_rate: 150.0
            }
          }
        }.to change(ExchangeRate, :count).by(1)

        expect(response).to redirect_to(exchange_rates_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new exchange rate" do
        expect {
          post exchange_rates_path, params: {
            exchange_rate: {
              year: nil,
              month: nil,
              usd_to_jpy_rate: nil
            }
          }
        }.not_to change(ExchangeRate, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /exchange_rates/:id/edit" do
    it "returns http success" do
      get edit_exchange_rate_path(exchange_rate)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /exchange_rates/:id" do
    context "with valid parameters" do
      it "updates the exchange rate" do
        patch exchange_rate_path(exchange_rate), params: {
          exchange_rate: {
            usd_to_jpy_rate: 160.0
          }
        }

        expect(exchange_rate.reload.usd_to_jpy_rate).to eq(160.0)
        expect(response).to redirect_to(exchange_rates_path)
      end
    end

    context "with invalid parameters" do
      it "does not update the exchange rate" do
        patch exchange_rate_path(exchange_rate), params: {
          exchange_rate: {
            usd_to_jpy_rate: nil
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /exchange_rates/:id" do
    it "destroys the exchange rate" do
      exchange_rate # create the exchange rate before the expect block
      expect {
        delete exchange_rate_path(exchange_rate)
      }.to change(ExchangeRate, :count).by(-1)

      expect(response).to redirect_to(exchange_rates_path)
    end
  end
end
