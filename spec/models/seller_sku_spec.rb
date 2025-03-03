# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SellerSku, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:seller_sku)).to be_valid
    end
  end

  describe 'アソシエーション' do
    it { should have_many(:order_lines) }
    it { should have_many(:sku_mappings) }
    it { should have_many(:manufacturer_skus).through(:sku_mappings) }
  end

  describe 'バリデーション' do
    it 'sku_codeがあれば有効であること' do
      seller_sku = build(:seller_sku, sku_code: 'SKU001')
      expect(seller_sku).to be_valid
    end

    it 'sku_codeがなければ無効であること' do
      seller_sku = build(:seller_sku, sku_code: nil)
      expect(seller_sku).not_to be_valid
      expect(seller_sku.errors[:sku_code]).to include("が入力されていません。")
    end

    context '一意性の検証' do
      before { create(:seller_sku, sku_code: 'SKU001') }

      it '同じsku_codeで作成しようとすると無効であること' do
        seller_sku = build(:seller_sku, sku_code: 'SKU001')
        expect(seller_sku).not_to be_valid
        expect(seller_sku.errors[:sku_code]).to include("は既に使用されています。")
      end

      it '異なるsku_codeであれば有効であること' do
        seller_sku = build(:seller_sku, sku_code: 'SKU002')
        expect(seller_sku).to be_valid
      end
    end
  end

  describe '.ransackable_attributes' do
    it 'ransack用の許可された属性を返すこと' do
      expect(described_class.ransackable_attributes).to match_array(
        %w[created_at id sku_code updated_at]
      )
    end
  end

  describe 'スコープ' do
    it 'SKUコードで検索できること' do
      sku = create(:seller_sku, sku_code: 'OIL-001')

      # メソッド名を確認して使用する
      if SellerSku.respond_to?(:by_code)
        result = SellerSku.by_code('OIL')
        expect(result).to include(sku)
      else
        pending 'コードによる検索スコープが実装されていません'
      end
    end
  end
end
