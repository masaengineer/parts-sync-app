require 'rails_helper'

RSpec.describe Sale, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:order) }
  end

  describe 'ransackable_attributes' do
    subject { Sale.ransackable_attributes }

    it { should include('created_at', 'updated_at', 'order_id', 'order_net_amount', 'order_gross_amount') }
  end

  describe 'ransackable_associations' do
    subject { Sale.ransackable_associations }

    it { should include('order') }
  end

  describe '金額属性' do
    subject { build(:sale) }

    it { should respond_to(:order_net_amount) }
    it { should respond_to(:order_gross_amount) }

    describe '金額の整合性' do
      it { expect(subject.order_net_amount).to be_a_kind_of(Numeric) }
      it { expect(subject.order_gross_amount).to be_a_kind_of(Numeric) }
      it { expect(subject.order_gross_amount).to be > subject.order_net_amount }
    end
  end
end
