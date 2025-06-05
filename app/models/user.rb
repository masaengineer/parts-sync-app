class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :orders, dependent: :destroy
  has_many :exchange_rates, dependent: :destroy
  attr_accessor :agreement

  validates :email, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :first_name, presence: true

  scope :with_ebay_account, -> { where.not(ebay_token: nil) }
  scope :demo_users, -> { where(is_demo: true) }
  scope :production_users, -> { where(is_demo: false) }

  def self.from_omniauth(auth)
    user = User.find_by(email: auth.info.email)

    if user
      user.update(provider: auth.provider, uid: auth.uid) unless user.provider && user.uid
      user
    else
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

  def full_name
    "#{last_name} #{first_name}"
  end
end
