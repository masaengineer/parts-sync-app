require 'rails_helper'

RSpec.describe MonthlyData, type: :model do
  let(:user) { create(:user) }

  describe 'バリデーション' do
    it '有効な属性を持つ月次データが有効であること' do
      monthly_data = build(:monthly_data, user: user)
      expect(monthly_data).to be_valid
    end

    it 'ユーザーがnilの場合は無効であること' do
      monthly_data = build(:monthly_data, user: nil)
      expect(monthly_data).not_to be_valid
    end

    it '年度がnilの場合は無効であること' do
      monthly_data = build(:monthly_data, user: user, year: nil)
      expect(monthly_data).not_to be_valid
    end

    it '月がnilの場合は無効であること' do
      monthly_data = build(:monthly_data, user: user, month: nil)
      expect(monthly_data).not_to be_valid
    end

    it '月が1から12の範囲外の場合は無効であること' do
      monthly_data = build(:monthly_data, user: user, month: 13)
      expect(monthly_data).not_to be_valid

      monthly_data = build(:monthly_data, user: user, month: 0)
      expect(monthly_data).not_to be_valid
    end

    it '同一ユーザーの同一年月のデータが重複していると無効であること' do
      create(:monthly_data, user: user, year: 2023, month: 1)
      duplicate_data = build(:monthly_data, user: user, year: 2023, month: 1)
      expect(duplicate_data).not_to be_valid
    end
  end

  describe '派生値の計算' do
    let(:monthly_data) {
      create(:monthly_data,
        user: user,
        revenue: 100000,
        procurement_cost: 40000,
        expenses: 30000
      )
    }

    it '粗利を正しく計算すること' do
      expect(monthly_data.gross_profit).to eq(60000)  # 100000 - 40000
    end

    it '限界利益を正しく計算すること' do
      expect(monthly_data.contribution_margin).to eq(30000)  # 60000 - 30000
    end

    it '限界利益率を正しく計算すること' do
      expect(monthly_data.contribution_margin_rate).to eq(30)  # (30000 / 100000) * 100
    end

    it '売上高が0の場合、限界利益率は0を返すこと' do
      zero_revenue_data = create(:monthly_data, user: user, revenue: 0, procurement_cost: 40000, expenses: 30000)
      expect(zero_revenue_data.contribution_margin_rate).to eq(0)
    end
  end

  describe 'スコープ' do
    before do
      create(:monthly_data, user: user, year: 2022, month: 1)
      create(:monthly_data, user: user, year: 2022, month: 2)
      create(:monthly_data, user: user, year: 2023, month: 1)
      create(:monthly_data, user: user, year: 2023, month: 2)

      other_user = create(:user)
      create(:monthly_data, user: other_user, year: 2023, month: 1)
    end

    it '指定した年のデータを取得すること' do
      expect(MonthlyData.for_year(2022).count).to eq(2)
      expect(MonthlyData.for_year(2023).count).to eq(3)
    end

    it '指定したユーザーのデータを取得すること' do
      expect(MonthlyData.for_user(user).count).to eq(4)
    end

    it 'ユーザーと年度を指定して正しくデータを取得すること' do
      data = MonthlyData.for_user(user).for_year(2023)
      expect(data.count).to eq(2)
      expect(data.pluck(:year).uniq).to eq([ 2023 ])
      expect(data.pluck(:user_id).uniq).to eq([ user.id ])
    end
  end
end
