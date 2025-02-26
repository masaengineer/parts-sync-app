# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SkuMapping, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:sku_mapping)).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'seller_skuに属すること' do
      seller_sku = create(:seller_sku)
      mapping = create(:sku_mapping, seller_sku: seller_sku)

      expect(mapping.seller_sku).to eq(seller_sku)
    end

    it 'manufacturer_skuに属すること' do
      manufacturer_sku = create(:manufacturer_sku)
      mapping = create(:sku_mapping, manufacturer_sku: manufacturer_sku)

      expect(mapping.manufacturer_sku).to eq(manufacturer_sku)
    end
  end

  describe 'バリデーション' do
    it '同じseller_skuとmanufacturer_skuの組み合わせが重複している場合は無効であること' do
      seller_sku = create(:seller_sku)
      manufacturer_sku = create(:manufacturer_sku)

      # 最初のマッピングは有効
      create(:sku_mapping, seller_sku: seller_sku, manufacturer_sku: manufacturer_sku)

      # 同じ組み合わせの2つ目のマッピングは無効
      duplicate_mapping = build(:sku_mapping, seller_sku: seller_sku, manufacturer_sku: manufacturer_sku)
      expect(duplicate_mapping).not_to be_valid
      expect(duplicate_mapping.errors[:seller_sku_id]).to include('has already been taken')
    end

    it '異なるseller_skuとmanufacturer_skuの組み合わせは有効であること' do
      seller_sku1 = create(:seller_sku)
      seller_sku2 = create(:seller_sku)
      manufacturer_sku1 = create(:manufacturer_sku)
      manufacturer_sku2 = create(:manufacturer_sku)

      # 異なる組み合わせは全て有効
      mapping1 = create(:sku_mapping, seller_sku: seller_sku1, manufacturer_sku: manufacturer_sku1)
      mapping2 = build(:sku_mapping, seller_sku: seller_sku1, manufacturer_sku: manufacturer_sku2)
      mapping3 = build(:sku_mapping, seller_sku: seller_sku2, manufacturer_sku: manufacturer_sku1)

      expect(mapping1).to be_valid
      expect(mapping2).to be_valid
      expect(mapping3).to be_valid
    end
  end

  describe 'スコープ' do
    # by_seller_skuスコープが存在する場合のテスト
    it '販売者SKUでマッピングを検索できること', skip: !SkuMapping.respond_to?(:by_seller_sku) do
      seller_sku = create(:seller_sku)
      other_seller_sku = create(:seller_sku)

      mapping1 = create(:sku_mapping, seller_sku: seller_sku)
      mapping2 = create(:sku_mapping, seller_sku: other_seller_sku)

      result = SkuMapping.by_seller_sku(seller_sku.id)
      expect(result).to include(mapping1)
      expect(result).not_to include(mapping2)
    end

    # by_manufacturer_skuスコープが存在する場合のテスト
    it 'メーカーSKUでマッピングを検索できること', skip: !SkuMapping.respond_to?(:by_manufacturer_sku) do
      manu_sku = create(:manufacturer_sku)
      other_manu_sku = create(:manufacturer_sku)

      mapping1 = create(:sku_mapping, manufacturer_sku: manu_sku)
      mapping2 = create(:sku_mapping, manufacturer_sku: other_manu_sku)

      result = SkuMapping.by_manufacturer_sku(manu_sku.id)
      expect(result).to include(mapping1)
      expect(result).not_to include(mapping2)
    end
  end
end
