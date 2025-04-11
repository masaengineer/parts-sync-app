class Manufacturer < ApplicationRecord
  enum :name, {
    toyota: "Toyota",
    honda: "Honda",
    nissan: "Nissan",
    mitsubishi: "Mitsubishi",
    subaru: "Subaru",
    mazda: "Mazda",
    suzuki: "Suzuki",
    lexus: "Lexus",
    daihatsu: "Daihatsu",
    isuzu: "Isuzu",
    yamaha: "Yamaha"
  }, prefix: true # name_toyota などのメソッドを使えるようにする

  validates :name, presence: true, inclusion: { in: names.keys.map(&:to_s) }
  has_many :manufacturer_skus
end
