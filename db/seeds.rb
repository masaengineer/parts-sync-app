# データベースをクリーンアップ
puts "🗑️ Cleaning database..."
[
  OrderSkuLink,
  Sale,
  Shipment,
  PaymentFee,
  Procurement,
  Order,
  SkuProductLink,
  Sku,
  Product,
  Manufacturer,
  User,
  Expense
].each(&:destroy_all)

# ユーザーの作成
puts "👥 Creating users..."
users = [
  {
    name: "Admin User",
    email: "admin@example.com",
    password: "password123",  # deviseはpasswordを自動的に暗号化します
    role: "admin",
    profile_picture_url: nil
  },
  {
    name: "Staff User",
    email: "staff@example.com",
    password: "password123",
    role: "staff",
    profile_picture_url: nil
  }
]

users = users.map do |attrs|
  User.create!(attrs)
end

# 追加のテストユーザー
18.times do |i|
  User.create!(
    name: "Test User #{i + 1}",
    email: "test#{i + 1}@example.com",
    password: "password123",
    role: "staff",
    profile_picture_url: nil
  )
end

# メーカーの作成
puts "🏭 Creating manufacturers..."
manufacturers = 20.times.map do |i|
  Manufacturer.create!(
    name: "Manufacturer #{i + 1}"
  )
end

# 商品の作成
puts "📦 Creating products..."
products = 20.times.map do |i|
  Product.create!(
    oem_part_number: "PART-#{format('%04d', i + 1)}",
    international_title: "International Product #{i + 1}",
    manufacturer: manufacturers.sample
  )
end

# SKUの作成
puts "🏷️ Creating SKUs..."
skus = 20.times.map do |i|
  Sku.create!(
    sku_code: "SKU-#{format('%04d', i + 1)}"
  )
end

# SKUと商品の紐付け
puts "🔗 Linking SKUs to products..."
20.times do |i|
  SkuProductLink.create!(
    sku: skus[i],
    product: products[i]
  )
end

# 注文の作成
puts "📝 Creating orders..."
20.times do |i|
  order = Order.create!(
    order_number: "ORD-#{format('%04d', i + 1)}",
    sale_date: Date.today - rand(1..90),
    user: users.sample,
    order_status: ["pending", "processing", "shipped", "delivered"].sample
  )

  # OrderSkuLinkの作成
  OrderSkuLink.create!(
    order: order,
    sku: skus.sample,
    quantity: rand(1..10),
    price: rand(1000..50000)
  )

  # 配送情報の作成
  Shipment.create!(
    order: order,
    tracking_number: "TRK-#{format('%04d', i + 1)}",
    customer_international_shipping: rand(2000..20000)
  )

  # 支払い手数料の作成
  PaymentFee.create!(
    order: order,
    fee_category: ["credit_card", "bank_transfer", "convenience_store"].sample,
    fee_amount: rand(100..1000)
  )

  # 調達情報の作成
  Procurement.create!(
    product: products.sample,
    purchase_price: rand(5000..100000),
    forwarding_fee: rand(500..2000),
    photo_fee: rand(100..500)
  )

  # 販売情報の作成
  Sale.create!(
    order: order,
    gross_amount: rand(10000..200000),
    net_amount: rand(8000..180000)
  )
end

# 経費の作成
puts "💰 Creating expenses..."
20.times do |i|
  Expense.create!(
    year: [2023, 2024].sample,
    month: rand(1..12),
    item_name: ["事務用品", "通信費", "交通費", "広告費", "家賃", "水道光熱費"].sample,
    amount: rand(1000..100000)
  )
end

puts "✅ Seed data creation completed!"
