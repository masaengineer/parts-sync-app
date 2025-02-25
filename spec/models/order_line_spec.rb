# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderLine, type: :model do
  describe 'Factory' do
    it 'has a valid factory' do
      expect(build(:order_line)).to be_valid
    end
  end

  describe 'Associations' do
    it { should belong_to(:seller_sku) }
    it { should belong_to(:order) }
  end

  describe 'Validations' do
    subject { build(:order_line) }

    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_presence_of(:line_item_id) }
  end

  describe '.ransackable_attributes' do
    it 'returns allowed attributes for ransack' do
      expect(described_class.ransackable_attributes).to match_array(
        %w[created_at id line_item_id line_item_name order_id quantity seller_sku_id unit_price updated_at]
      )
    end
  end

  describe '.ransackable_associations' do
    it 'returns allowed associations for ransack' do
      expect(described_class.ransackable_associations).to match_array(
        %w[order seller_sku]
      )
    end
  end
end
