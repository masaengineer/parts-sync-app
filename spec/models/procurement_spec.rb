# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Procurement, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:procurement, order: create(:order))).to be_valid
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:order) }
  end

  describe 'バリデーション' do
    it '購入価格があれば有効であること' do
      procurement = build(:procurement, order: create(:order), purchase_price: 5000)
      expect(procurement).to be_valid
    end

    it '購入価格がなければ無効であること' do
      procurement = build(:procurement, order: create(:order), purchase_price: nil)
      expect(procurement).not_to be_valid
      expect(procurement.errors[:purchase_price]).to include("が入力されていません。")
    end

    it '注文IDがなければ無効であること' do
      procurement = build(:procurement, order_id: nil)
      expect(procurement).not_to be_valid
      expect(procurement.errors[:order_id]).to include("が入力されていません。")
    end
  end

  describe '#total_cost' do
    context '全ての費用が設定されている場合' do
      it '総コストを正しく計算すること' do
        procurement = build(:procurement,
          purchase_price: 5000,
          forwarding_fee: 500,
          handling_fee: 200
        )

        expect(procurement.total_cost).to eq(5700)
      end
    end

    context '一部の費用が設定されていない場合' do
      it '存在する費用のみで総コストを計算すること' do
        procurement = build(:procurement,
          purchase_price: 5000,
          forwarding_fee: nil,
          handling_fee: 200
        )

        expect(procurement.total_cost).to eq(5200)
      end
    end

    context '購入価格のみが設定されている場合' do
      it '購入価格が総コストになること' do
        procurement = build(:procurement,
          purchase_price: 5000,
          forwarding_fee: nil,
          handling_fee: nil
        )

        expect(procurement.total_cost).to eq(5000)
      end
    end
  end
end
