require "csv"

class WisewillDataSheetImporter
  class MissingOrderNumbersError < StandardError; end
  class OrderNotFoundError < StandardError; end
  class MissingPurchasePriceError < StandardError; end

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

    validate_purchase_price(csv)
    validate_order_numbers(csv)

    ActiveRecord::Base.transaction do
      csv.each_with_index do |row, i|
        Rails.logger.info "[Filtere] 行 #{i + 1}: #{row.to_h.inspect}"
        import_row(row)
      end
    end

  rescue StandardError => e
    Rails.logger.error "[WisewillDataSheetImporter] エラー発生: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def validate_purchase_price(csv)
    csv.each_with_index do |row, index|
      if row["purchase_price"].blank?
        raise MissingPurchasePriceError, "CSVの#{index + 2}行目: purchase_priceが空です。"
      end
    end
  end

  def validate_order_numbers(csv)
    csv.each_with_index do |row, index|
      if row["order_number"].blank?
        raise MissingOrderNumbersError, "CSVの#{index + 2}行目: order_numberが空です。"
      end
    end
  end

  def import_row(row)
    order_number      = row["order_number"]&.strip
    manufacturer_name = row["manufacturer_name"]&.strip
    purchase_price    = to_decimal(row["purchase_price"])
    handling_fee      = to_decimal(row["handling_fee"])
    option_fee        = to_decimal(row["option_fee"])
    year              = row["year"]&.to_i
    month             = row["month"]&.to_i
    sheet_name        = row["sheet_name"]

    if order_number.blank?
      Rails.logger.warn "[WisewillDataSheetImporter] order_numberが空のため、この行をスキップします: #{row.to_h.inspect}"
      return
    end

    order = @user.orders.find_by(order_number: order_number)

    unless order
      raise OrderNotFoundError, "Order with order_number #{order_number} not found"
    end

    if manufacturer_name.present?
      Manufacturer.find_or_create_by!(name: manufacturer_name)
    end

    create_procurement(order, purchase_price, handling_fee)

    create_expense(order, option_fee, year, month) if option_fee.present?
  end

  def create_procurement(order, purchase_price, handling_fee)
    return unless purchase_price || handling_fee

    procurement = order.procurement || order.build_procurement
    procurement.update!(
      purchase_price: purchase_price,
      handling_fee: handling_fee
    )
  end

  def create_expense(order, option_fee, year, month)
    return unless option_fee

    current_date = Date.today
    year = year.presence || current_date.year
    month = month.presence || current_date.month

    expense = Expense.find_or_initialize_by(
      order_id: order.id,
      expense_type: "option_fee"
    )

    expense.update!(
      amount: option_fee,
      option_fee: option_fee,
      year: year,
      month: month,
      item_name: "オプション料金（#{order.order_number}）"
    )
  end

  def to_decimal(value)
    return nil if value.nil? || value.strip.empty?
    cleaned = value.to_s.gsub(/["',]/, "")
    BigDecimal(cleaned)
  rescue ArgumentError
    nil
  end
end
