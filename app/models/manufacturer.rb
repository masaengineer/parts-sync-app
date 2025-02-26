# == Schema Information
#
# Table name: manufacturers
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_manufacturers_on_name  (name)
#
class Manufacturer < ApplicationRecord
  enum :name, {
    toyota: "Toyota",
    honda: "Honda",
    nissan: "Nissan",
    mitsubishi: "Mitsubishi",
    subaru: "Subaru",
    mazda: "Mazda", # "Matsuda" ではなく "Mazda"
    suzuki: "Suzuki",
    lexus: "Lexus",
    daihatsu: "Daihatsu",
    isuzu: "Isuzu",
    yamaha: "Yamaha"
  }, prefix: true # name_toyota などのメソッドを使えるようにする

  validates :name, presence: true, inclusion: { in: names.keys.map(&:to_s) }
  has_many :manufacturer_skus
end
