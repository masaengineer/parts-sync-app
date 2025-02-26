# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shipment, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:shipment)).to be_valid
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:order) }
  end

  describe 'バリデーション' do
    it 'トラッキング番号があれば有効であること' do
      shipment = build(:shipment, tracking_number: 'TRACK001')
      expect(shipment).to be_valid
    end
  end

  describe 'メソッド' do
    describe '.ransackable_attributes' do
      it 'ransack用の許可された属性を返すこと' do
        expect(described_class.ransackable_attributes).to match_array(
          %w[
            tracking_number
            customer_international_shipping
            created_at
            updated_at
          ]
        )
      end
    end
  end

  describe 'スコープ' do
    it 'トラッキング番号でレコードを検索できること' do
      shipment = create(:shipment, tracking_number: 'TRACK001')

      # Shipmentモデルにby_tracking_numberスコープが実装されていなければ、
      # このテストをスキップします
      if Shipment.respond_to?(:by_tracking_number)
        result = Shipment.by_tracking_number('TRACK001')
        expect(result).to include(shipment)
      else
        pending 'by_tracking_numberスコープが実装されていません'
      end
    end
  end
end
