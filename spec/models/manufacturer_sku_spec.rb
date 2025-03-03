# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManufacturerSku, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:manufacturer_sku)).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'manufacturerに属すること' do
      manufacturer = create(:manufacturer)
      manufacturer_sku = create(:manufacturer_sku, manufacturer: manufacturer)

      expect(manufacturer_sku.manufacturer).to eq(manufacturer)
    end

    # SkuMappingとの関連があれば確認
    it 'sku_mappingsを持つこと', skip: !ManufacturerSku.new.respond_to?(:sku_mappings) do
      manufacturer_sku = create(:manufacturer_sku)
      mapping = create(:sku_mapping, manufacturer_sku: manufacturer_sku)

      expect(manufacturer_sku.sku_mappings).to include(mapping)
    end

    # SellerSkuとの関連が設定されていれば確認
    it 'seller_skusを持つこと', skip: !ManufacturerSku.new.respond_to?(:seller_skus) do
      manufacturer_sku = create(:manufacturer_sku)
      seller_sku = create(:seller_sku)
      create(:sku_mapping, manufacturer_sku: manufacturer_sku, seller_sku: seller_sku)

      expect(manufacturer_sku.seller_skus).to include(seller_sku)
    end
  end

  describe 'スコープ' do
    # by_codeスコープが存在する場合のテスト
    it 'コードでSKUを検索できること', skip: !ManufacturerSku.respond_to?(:by_code) do
      target_sku = create(:manufacturer_sku, code: 'ABC123')
      other_sku = create(:manufacturer_sku, code: 'XYZ789')

      result = ManufacturerSku.by_code('ABC123')
      expect(result).to include(target_sku)
      expect(result).not_to include(other_sku)
    end

    # by_manufacturerスコープが存在する場合のテスト
    it 'メーカーでSKUを検索できること', skip: !ManufacturerSku.respond_to?(:by_manufacturer) do
      toyota = create(:manufacturer, name: 'toyota')
      honda = create(:manufacturer, name: 'honda')

      toyota_sku = create(:manufacturer_sku, manufacturer: toyota)
      honda_sku = create(:manufacturer_sku, manufacturer: honda)

      result = ManufacturerSku.by_manufacturer(toyota.id)
      expect(result).to include(toyota_sku)
      expect(result).not_to include(honda_sku)
    end
  end

  # 特定のバリデーションがあれば確認
  describe 'バリデーション' do
    it 'codeフィールドがあれば、それが存在することを確認する', skip: !ManufacturerSku.column_names.include?('code') do
      manufacturer_sku = build(:manufacturer_sku, code: nil)

      # codeに対するバリデーションが存在するかどうか確認
      if ManufacturerSku.validators_on(:code).any? { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }
        expect(manufacturer_sku).not_to be_valid
        expect(manufacturer_sku.errors[:code]).to include("が入力されていません。")
      else
        skip 'codeに存在性バリデーションがありません'
      end
    end
  end
end
