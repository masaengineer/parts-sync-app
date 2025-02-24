# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           not null
#  profile_picture_url    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  last_name              :string
#  first_name             :string
#  provider               :string
#  uid                    :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :orders, dependent: :destroy
  attr_accessor :agreement

  validates :email, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :first_name, presence: true

  scope :with_ebay_account, -> { where.not(ebay_token: nil) }

  def self.from_omniauth(auth)
    # email から既存ユーザーを検索してみる
    user = User.find_by(email: auth.info.email)

    if user
      # 既に同じ email のユーザーがいれば、provider, uid を更新して保存
      user.update(provider: auth.provider, uid: auth.uid) unless user.provider && user.uid
      user
    else
      # 存在しないなら新規作成
      create do |new_user|
        new_user.email = auth.info.email
        new_user.password = Devise.friendly_token[0, 20]
        new_user.last_name = auth.info.last_name
        new_user.first_name = auth.info.first_name
        new_user.provider = auth.provider
        new_user.uid = auth.uid
        new_user.profile_picture_url = auth.info.image
      end
    end
  end

  # フルネームを返すメソッド
  def full_name
    "#{last_name} #{first_name}"
  end
end
