# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'Factory' do
    it 'has a valid factory' do
      expect(build(:order)).to be_valid
    end

    it 'has a valid factory with order lines' do
      expect(create(:order, :with_order_lines)).to be_valid
    end

    it 'has a valid factory with complete associations' do
      expect(create(:order, :complete)).to be_valid
    end
  end

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should have_many(:order_lines).dependent(:destroy) }
    it { should have_many(:payment_fees).dependent(:destroy) }
    it { should have_one(:procurement).dependent(:destroy) }
    it { should have_many(:sales) }
    it { should have_one(:shipment) }
  end

  describe 'Validations' do
    subject { build(:order) }

    it { should validate_presence_of(:order_number) }
    it { should validate_uniqueness_of(:order_number) }
  end

  describe '#total_procurement_cost' do
    context 'when procurement exists' do
      let(:order) { create(:order, :with_procurement) }

      it 'returns the total cost from procurement' do
        expect(order.total_procurement_cost).to eq(order.procurement.total_cost)
      end
    end

    context 'when procurement does not exist' do
      let(:order) { create(:order) }

      it 'returns 0' do
        expect(order.total_procurement_cost).to eq(0)
      end
    end
  end

  describe '.ransackable_attributes' do
    it 'returns allowed attributes for ransack' do
      expect(described_class.ransackable_attributes).to match_array(
        %w[order_number sale_date created_at updated_at user_id]
      )
    end
  end

  describe '.ransackable_associations' do
    it 'returns allowed associations for ransack' do
      expect(described_class.ransackable_associations).to match_array(
        %w[user sale order_lines skus procurement shipment payment_fees]
      )
    end
  end
end
