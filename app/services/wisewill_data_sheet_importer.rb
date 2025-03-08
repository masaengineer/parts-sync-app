require "csv"

class WisewillDataSheetImporter
  # カスタムエラークラスの定義
  class MissingSkusError < StandardError; end
  class OrderNotFoundError < StandardError; end # Orderが見つからない場合のエラー
  class MissingPurchasePriceError < StandardError; end # purchase_priceが空の場合のエラー

  def initialize(csv_path, user)
    @csv_path = csv_path
    @user = user
  end

  def import
    Rails.logger.info "[WisewillDataSheetImporter] インポート開始: #{@csv_path}"

    # BOMを除去し、UTF-8としてCSVを読み込む
    csv_text = File.read(@csv_path).force_encoding("UTF-8").sub("\xEF\xBB\xBF", "")
    csv = CSV.parse(csv_text, headers: true)

    Rails.logger.info "[WisewillDataSheetImporter] CSVの行数: #{csv.size} (ヘッダーを除く)"

    # purchase_priceの存在チェック
    validate_purchase_price(csv)




    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, i|
        Rails.logger.info "[Filtere] 行 #{i + 1}: #{row.to_h.inspect}"
        import_row(row)


      end
    end



  rescue StandardError => e
    Rails.logger.error "[WisewillDataSheetImporter] エラー発生: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # 発生したエラーを再度投げる
  end

  private

  # purchase_priceの存在チェック
  def validate_purchase_price(csv)
    csv.each_with_index do |row, index|
      if row["purchase_price"].blank?
        # エラーメッセージに行番号を含める
        raise MissingPurchasePriceError, "CSVの#{index + 2}行目: purchase_priceが空です。"
      end
    end
  end

  # 行ごとの処理
  def import_row(row)
    # CSVの各カラムを取得
    order_number      = row["order_number"]&.strip
    manufacturer_name = row["manufacturer_name"]&.strip
    purchase_price    = to_decimal(row["purchase_price"])
    handling_fee      = to_decimal(row["handling_fee"])
    option_fee         = to_decimal(row["option_fee"])
すがな
    # 必須項目のバリデーション
    if order_number.blank?
      Rails.logger.warn "[WisewillDataSheetImporter] order_numberが空のため、この行をスキップします: #{row.to_h.inspect}"
      return
    end

    # 1. Orderレコードを検索
    order = @user.orders.find_by(order_number: order_number)

    # Orderが見つからない場合はエラー
    unless order
      raise OrderNotFoundError, "Order with order_number #{order_number} not found"

    end

    # 2. Manufacturerレコードを作成または検索（必要な場合）
    if manufacturer_name.present?
      Manufacturer.find_or_create_by!(name: manufacturer_name)
    end

    # 3. 既存のorderを使ってProcurementレコードを作成
    create_procurement(order, purchase_price, handling_fee, option_fee)

  end

  # Procurementレコードの作成
  def create_procurement(order, purchase_price, handling_fee, option_fee)
    return unless purchase_price || handling_fee || option_fee

    # 既存のProcurementレコードを更新するか、新しいものを作成
    procurement = order.procurement || order.build_procurement
    procurement.update!(
      purchase_price: purchase_price,
      handling_fee: handling_fee,
      option_fee: option_fee

    )


  end

  # 文字列をBigDecimalに変換
  def to_decimal(value)
    return nil if value.nil? || value.strip.empty?
    BigDecimal(value)

  rescue ArgumentError
    nil
  end
end
