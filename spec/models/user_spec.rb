# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe User, type: :model do
  describe 'Factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    # ebay_tokenカラムが存在しないため、一時的にコメントアウト
    # it 'has a valid factory with ebay token' do
    #   expect(build(:user, :with_ebay_token)).to be_valid
    # end

    it 'has a valid factory with google oauth' do
      expect(build(:user, :with_google_oauth)).to be_valid
    end
  end

  describe 'Validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:password) }
  end

  describe 'Associations' do
    it { should have_many(:orders) }
  end

  # ebay_tokenカラムが存在しないため、一時的にコメントアウト
  # describe 'Scopes' do
  #   describe '.with_ebay_account' do
  #     let!(:user_with_ebay) { create(:user, :with_ebay_token) }
  #     let!(:user_without_ebay) { create(:user) }

  #     it 'returns only users with ebay token' do
  #       expect(described_class.with_ebay_account).to include(user_with_ebay)
  #       expect(described_class.with_ebay_account).not_to include(user_without_ebay)
  #     end
  #   end
  # end

  describe 'Instance Methods' do
    describe '#full_name' do
      let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

      it 'returns concatenated last_name and first_name' do
        expect(user.full_name).to eq('Doe John')
      end
    end
  end

  describe 'Class Methods' do
    describe '.from_omniauth' do
      let(:auth) do
        OpenStruct.new(
          provider: 'google_oauth2',
          uid: '123456',
          info: OpenStruct.new(
            email: 'test@example.com',
            first_name: 'John',
            last_name: 'Doe',
            image: 'http://example.com/image.jpg'
          )
        )
      end

      context 'when user exists' do
        let!(:existing_user) { create(:user, email: 'test@example.com') }

        it 'updates provider and uid' do
          user = described_class.from_omniauth(auth)
          expect(user).to eq(existing_user)
          expect(user.provider).to eq('google_oauth2')
          expect(user.uid).to eq('123456')
        end

        it 'does not create a new user' do
          expect { described_class.from_omniauth(auth) }.not_to change(User, :count)
        end
      end

      context 'when user does not exist' do
        it 'creates a new user' do
          expect { described_class.from_omniauth(auth) }.to change(User, :count).by(1)
        end

        it 'sets correct attributes' do
          user = described_class.from_omniauth(auth)
          expect(user).to have_attributes(
            email: 'test@example.com',
            first_name: 'John',
            last_name: 'Doe',
            provider: 'google_oauth2',
            uid: '123456',
            profile_picture_url: 'http://example.com/image.jpg'
          )
        end
      end
    end
  end

  describe 'OAuth Authentication' do
    let(:auth_hash) do
      OpenStruct.new(
        provider: 'google_oauth2',
        uid: '123456789',
        info: OpenStruct.new(
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe',
          image: 'https://example.com/photo.jpg'
        )
      )
    end

    context 'when user does not exist' do
      it 'creates a new user with correct attributes' do
        expect {
          user = User.from_omniauth(auth_hash)
          expect(user).to have_attributes(
            email: 'test@example.com',
            first_name: 'John',
            last_name: 'Doe',
            provider: 'google_oauth2',
            uid: '123456789',
            profile_picture_url: 'https://example.com/photo.jpg'
          )
        }.to change(User, :count).by(1)
      end

      it 'sets a random password for new users' do
        user = User.from_omniauth(auth_hash)
        expect(user.encrypted_password).to be_present
      end
    end

    context 'when user exists but without OAuth credentials' do
      let!(:existing_user) { create(:user, email: 'test@example.com') }

      it 'updates existing user with OAuth credentials' do
        expect {
          user = User.from_omniauth(auth_hash)
          expect(user).to eq(existing_user)
          expect(user).to have_attributes(
            provider: 'google_oauth2',
            uid: '123456789'
          )
        }.not_to change(User, :count)
      end
    end

    context 'when user exists with OAuth credentials' do
      let!(:existing_user) do
        create(:user,
          email: 'test@example.com',
          provider: 'google_oauth2',
          uid: '123456789'
        )
      end

      it 'returns existing user without modifying attributes' do
        expect {
          user = User.from_omniauth(auth_hash)
          expect(user).to eq(existing_user)
          expect(user.provider).to eq('google_oauth2')
          expect(user.uid).to eq('123456789')
        }.not_to change(User, :count)
      end
    end
  end

  describe 'Order Management' do
    let(:user) { create(:user) }

    describe 'associations' do
      it 'can have multiple orders' do
        orders = create_list(:order, 3, user: user)
        expect(user.orders.count).to eq(3)
      end

      it 'destroys associated orders when user is destroyed' do
        create_list(:order, 2, user: user)
        expect {
          user.destroy
        }.to change(Order, :count).by(-2)
      end
    end

    describe 'order history' do
      before do
        create(:order, user: user, created_at: 1.day.ago)
        create(:order, user: user, created_at: 2.days.ago)
      end

      it 'returns orders in chronological order' do
        expect(user.orders.order(created_at: :desc).first.created_at).to be > user.orders.order(created_at: :desc).last.created_at
      end
    end
  end

  describe 'Devise functionality' do
    describe 'password validation' do
      it 'requires password to be at least 6 characters' do
        user = build(:user, password: '12345', password_confirmation: '12345')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('は6文字以上で入力してください')
      end

      it 'requires password confirmation to match password' do
        user = build(:user, password: 'password', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include('とパスワードの入力が一致しません')
      end
    end

    describe 'password recovery' do
      let(:user) { create(:user) }

      it 'generates reset password token' do
        expect {
          user.send_reset_password_instructions
        }.to change { user.reset_password_token }.from(nil)
        expect(user.reset_password_sent_at).to be_present
      end
    end

    describe 'remember me functionality' do
      let(:user) { create(:user) }

      it 'sets remember created at when remembering the user' do
        expect {
          user.remember_me!
        }.to change { user.remember_created_at }.from(nil)
      end

      it 'clears remember created at when forgetting the user' do
        user.remember_me!
        expect {
          user.forget_me!
        }.to change { user.remember_created_at }.to(nil)
      end
    end
  end
end
