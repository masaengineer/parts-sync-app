# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sale, type: :model do
  describe 'ファクトリー' do
    it '有効なファクトリーを持つこと' do
      expect(build(:sale)).to be_valid
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:order) }
  end

  describe 'バリデーション' do
    it 'order_net_amountがあれば有効であること' do
      sale = build(:sale, order_net_amount: 100.0)
      expect(sale).to be_valid
    end
  end

  describe 'メソッド' do
    describe '.ransackable_attributes' do
      it 'ransack用の許可された属性を返すこと' do
        expect(described_class.ransackable_attributes).to match_array(
          %w[
            created_at
            updated_at
            order_id
            order_net_amount
            order_gross_amount
          ]
        )
      end
    end

    describe '.ransackable_associations' do
      it 'ransack用の許可された関連付けを返すこと' do
        expect(described_class.ransackable_associations).to match_array(
          %w[order]
        )
      end
    end
  end
end
