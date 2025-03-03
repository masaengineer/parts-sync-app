require "csv"

class WisewillDataSheetImporter
  # カスタムエラークラスの定義
  class MissingSkusError < StandardError; end
  class OrderNotFoundError < StandardError; end # Orderが見つからない場合のエラー
  class MissingPurchasePriceError < StandardError; end # purchase_priceが空の場合のエラー
  class MissingSkuError < StandardError; end # SKUが空の場合のエラー
  class ShipmentNotFoundError < StandardError; end # 出荷情報が見つからない場合のエラー

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
    # SKUの存在チェック
    validate_sku(csv)

    imported_count = 0
    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, i|
        Rails.logger.info "[WisewillDataSheetImporter] 行 #{i + 1}: #{row.to_h.inspect}"
        if import_row(row)
          imported_count += 1
        end
      end
    end

    Rails.logger.info "[WisewillDataSheetImporter] インポート完了: #{imported_count}件の調達情報を登録/更新しました"
    return imported_count
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
  
  # SKUの存在チェック
  def validate_sku(csv)
    csv.each_with_index do |row, index|
      if row["sku_code"].blank?
        # エラーメッセージに行番号を含める
        raise MissingSkuError, "CSVの#{index + 2}行目: sku_codeが空です。"
      end
    end
  end

  # 行ごとの処理
  def import_row(row)
    # CSVの各カラムを取得
    tracking_number   = row["tracking_number"]&.strip
    sku_code          = row["sku_code"]&.strip
    purchase_price    = to_decimal(row["purchase_price"])
    handling_fee      = to_decimal(row["handling_fee"])
    option_fee        = to_decimal(row["option_fee"])
    forwarding_fee    = to_decimal(row["forwarding_fee"])

    # トラッキング番号の確認
    if tracking_number.blank?
      Rails.logger.warn "[WisewillDataSheetImporter] トラッキング番号が空のため、この行をスキップします: #{row.to_h.inspect}"
      return false
    end

    # 1. トラッキング番号からShipmentを検索
    shipment = Shipment.find_by(tracking_number: tracking_number)
    
    # Shipmentが見つからない場合
    unless shipment
      Rails.logger.warn "[WisewillDataSheetImporter] トラッキング番号 #{tracking_number} に対応する出荷情報が見つかりません"
      return false
    end

    # 2. Shipmentから関連するOrderを取得
    order = shipment.order

    # 3. 既存のorderを使ってProcurementレコードを作成
    create_procurement(order, purchase_price, handling_fee, option_fee, forwarding_fee)
    return true
  end

  # Procurementレコードの作成
  def create_procurement(order, purchase_price, handling_fee, option_fee, forwarding_fee)
    return false unless purchase_price

    # 既存のProcurementレコードを更新するか、新しいものを作成
    procurement = order.procurement || order.build_procurement
    procurement.update!(
      purchase_price: purchase_price,
      handling_fee: handling_fee,
      option_fee: option_fee,
      forwarding_fee: forwarding_fee
    )
    
    return true
  end

  # 文字列をBigDecimalに変換
  def to_decimal(value)
    return nil if value.nil? || value.to_s.strip.empty?
    # カンマを取り除いて変換
    BigDecimal(value.to_s.gsub(',', ''))
  rescue ArgumentError
    nil
  end
end
