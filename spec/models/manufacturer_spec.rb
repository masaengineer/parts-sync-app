# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Manufacturer, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:manufacturer)).to be_valid
    end
  end

  describe 'バリデーション' do
    it '名前があれば有効であること' do
      manufacturer = build(:manufacturer, name: 'toyota')
      expect(manufacturer).to be_valid
    end

    it '名前がなければ無効であること' do
      manufacturer = build(:manufacturer, name: nil)
      expect(manufacturer).not_to be_valid
      expect(manufacturer.errors[:name]).to include("can't be blank")
    end

    it '名前が列挙型の値の中になければ無効であること' do
      manufacturer = build(:manufacturer, name: 'invalid_name')
      expect(manufacturer).not_to be_valid
      expect(manufacturer.errors[:name]).to include('is not included in the list')
    end

    context '列挙型の値' do
      it '各メーカー名を指定して有効なインスタンスを作成できること' do
        %w[toyota honda nissan mitsubishi subaru mazda suzuki lexus daihatsu isuzu yamaha].each do |name|
          manufacturer = build(:manufacturer, name: name)
          expect(manufacturer).to be_valid
        end
      end
    end
  end

  describe 'アソシエーション' do
    it 'manufacturer_skusを多数持つこと' do
      manufacturer = create(:manufacturer)
      manu_sku1 = create(:manufacturer_sku, manufacturer: manufacturer)
      manu_sku2 = create(:manufacturer_sku, manufacturer: manufacturer)

      expect(manufacturer.manufacturer_skus).to include(manu_sku1, manu_sku2)
    end
  end

  describe '列挙型メソッド' do
    it 'プレフィックス付きのメーカー名メソッドを持つこと' do
      manufacturer = create(:manufacturer, name: 'toyota')

      # name_toyotaなどのメソッドが存在するか確認
      expect(manufacturer.respond_to?(:name_toyota?)).to be_truthy
    end

    it 'namesメソッドが全メーカー名を返すこと' do
      expected_names = {
        'toyota' => 'Toyota',
        'honda' => 'Honda',
        'nissan' => 'Nissan',
        'mitsubishi' => 'Mitsubishi',
        'subaru' => 'Subaru',
        'mazda' => 'Mazda',
        'suzuki' => 'Suzuki',
        'lexus' => 'Lexus',
        'daihatsu' => 'Daihatsu',
        'isuzu' => 'Isuzu',
        'yamaha' => 'Yamaha'
      }

      expect(Manufacturer.names).to eq(expected_names)
    end
  end
end
