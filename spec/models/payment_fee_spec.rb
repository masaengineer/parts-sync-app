# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentFee, type: :model do
  describe 'アソシエーション' do
    it 'orderに属していること' do
      expect(PaymentFee.reflect_on_association(:order).macro).to eq :belongs_to
    end
  end

  describe 'バリデーション' do
    it 'fee_amount、fee_categoryが存在する場合、有効であること' do
      payment_fee = build(:payment_fee)
      expect(payment_fee).to be_valid
    end

    it 'fee_amountが存在しない場合、無効であること' do
      payment_fee = build(:payment_fee, fee_amount: nil)
      expect(payment_fee).not_to be_valid
      expect(payment_fee.errors[:fee_amount]).to include('が入力されていません。')
    end

    it 'fee_categoryが存在しない場合、無効であること' do
      payment_fee = build(:payment_fee, fee_category: nil)
      expect(payment_fee).not_to be_valid
      expect(payment_fee.errors[:fee_category]).to include('が入力されていません。')
    end

    it 'fee_amountが数値でない場合、無効であること' do
      payment_fee = build(:payment_fee, fee_amount: 'abc')
      expect(payment_fee).not_to be_valid
      expect(payment_fee.errors[:fee_amount]).to include('は数値で入力してください')
    end
  end

  describe 'enumの定義' do
    describe 'transaction_type' do
      it 'saleが定義されていること' do
        payment_fee = create(:payment_fee, transaction_type: :sale)
        expect(payment_fee.sale?).to be true
        expect(PaymentFee.transaction_types[:sale]).to eq('SALE')
      end

      it 'non_sale_chargeが定義されていること' do
        payment_fee = create(:payment_fee, transaction_type: :non_sale_charge)
        expect(payment_fee.non_sale_charge?).to be true
        expect(PaymentFee.transaction_types[:non_sale_charge]).to eq('NON_SALE_CHARGE')
      end

      it 'shipping_labelが定義されていること' do
        payment_fee = create(:payment_fee, transaction_type: :shipping_label)
        expect(payment_fee.shipping_label?).to be true
        expect(PaymentFee.transaction_types[:shipping_label]).to eq('SHIPPING_LABEL')
      end

      it 'refundが定義されていること' do
        payment_fee = create(:payment_fee, transaction_type: :refund)
        expect(payment_fee.refund?).to be true
        expect(PaymentFee.transaction_types[:refund]).to eq('REFUND')
      end
    end

    describe 'fee_category' do
      it 'final_value_feeが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :final_value_fee)
        expect(payment_fee.final_value_fee?).to be true
        expect(PaymentFee.fee_categories[:final_value_fee]).to eq('FINAL_VALUE_FEE')
      end

      it 'final_value_fee_fixed_per_orderが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :final_value_fee_fixed_per_order)
        expect(payment_fee.final_value_fee_fixed_per_order?).to be true
        expect(PaymentFee.fee_categories[:final_value_fee_fixed_per_order]).to eq('FINAL_VALUE_FEE_FIXED_PER_ORDER')
      end

      it 'international_feeが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :international_fee)
        expect(payment_fee.international_fee?).to be true
        expect(PaymentFee.fee_categories[:international_fee]).to eq('INTERNATIONAL_FEE')
      end

      it 'insertion_feeが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :insertion_fee)
        expect(payment_fee.insertion_fee?).to be true
        expect(PaymentFee.fee_categories[:insertion_fee]).to eq('INSERTION_FEE')
      end

      it 'add_feeが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :add_fee)
        expect(payment_fee.add_fee?).to be true
        expect(PaymentFee.fee_categories[:add_fee]).to eq('AD_FEE')
      end

      it 'regulatory_operating_feeが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :regulatory_operating_fee)
        expect(payment_fee.regulatory_operating_fee?).to be true
        expect(PaymentFee.fee_categories[:regulatory_operating_fee]).to eq('REGULATORY_OPERATING_FEE')
      end

      it 'undefinedが定義されていること' do
        payment_fee = create(:payment_fee, fee_category: :undefined)
        expect(payment_fee.undefined?).to be true
        expect(PaymentFee.fee_categories[:undefined]).to eq('UNDEFINED')
      end
    end
  end

  describe 'スコープ' do
    before do
      @order = create(:order)
      @final_value_fee = create(:payment_fee, order: @order, fee_category: :final_value_fee)
      @international_fee = create(:payment_fee, order: @order, fee_category: :international_fee)
      @insertion_fee = create(:payment_fee, order: @order, fee_category: :insertion_fee)
    end

    it 'by_categoryでカテゴリーによるフィルタリングができること' do
      expect(PaymentFee.by_category(:final_value_fee)).to include(@final_value_fee)
      expect(PaymentFee.by_category(:final_value_fee)).not_to include(@international_fee, @insertion_fee)

      expect(PaymentFee.by_category(:international_fee)).to include(@international_fee)
      expect(PaymentFee.by_category(:international_fee)).not_to include(@final_value_fee, @insertion_fee)
    end
  end
end
