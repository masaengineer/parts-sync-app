require "csv"

# CpassDataSheetImporter
# - CSVからtracking_numberをキーにShipmentを探す
# - 送料と還元金額をチェックしてshipping_costを設定
# - F列の還元金額が負の値の場合は、最終的な請求金額はA列の金額。還元金額が0の場合は、最終的な請求金額はD列。

module Importers
  class CpassDataSheetImporter
    class PositiveDiscountError < StandardError; end

    def initialize(csv_path, user)
      @csv_path = csv_path
      @user = user
    end

    # CSV読み込み後、行ごとにimport_rowを呼ぶ
    def import
      Rails.logger.info "[CpassDataSheetImporter] Starting import from #{@csv_path}"

      csv = CSV.read(@csv_path, headers: true)
      Rails.logger.info "[CpassDataSheetImporter] CSV has #{csv.size} rows (excluding header)."

      ActiveRecord::Base.transaction do
        csv.each_with_index do |row, i|
          Rails.logger.info "[CpassDataSheetImporter] Row #{i + 1}: #{row.to_h.inspect}"
          import_row(row)
        end
      end
    rescue PositiveDiscountError => e
      Rails.logger.error "[CpassDataSheetImporter] PositiveDiscountError encountered: #{e.message}"
      raise e
    end

    private

    # 1行単位の処理
    def import_row(row)
      tracking_number = row["注文番号"]&.strip
      if tracking_number.blank?
        Rails.logger.warn "[CpassDataSheetImporter] Skipping row due to blank tracking_number. Row: #{row.to_h.inspect}"
        return
      end

      Rails.logger.info "[CpassDataSheetImporter] Tracking Number: #{tracking_number}"

      discount_value = to_decimal(row["還元金額（円）"])
      if discount_value.nil?
        Rails.logger.warn "[CpassDataSheetImporter] discount_value is nil. Row: #{row.to_h.inspect}"
        return
      end

      shipping_cost_column =
        if discount_value < 0
          Rails.logger.info "[CpassDataSheetImporter] discount_value < 0 => using \"金額（円）\""
          "金額（円）"
        elsif discount_value == 0
          Rails.logger.info "[CpassDataSheetImporter] discount_value == 0 => using \"ご請求金額（円）\""
          "ご請求金額（円）"
        else
          msg = "Positive discount encountered: #{tracking_number}"
          Rails.logger.error "[CpassDataSheetImporter] #{msg}"
          raise PositiveDiscountError, msg
        end

      shipping_cost_value = row[shipping_cost_column]
      if shipping_cost_value.nil? || shipping_cost_value.strip.empty?
        Rails.logger.warn "[CpassDataSheetImporter] No shipping cost found in column #{shipping_cost_column}. Row: #{row.to_h.inspect}"
        return
      end

      shipping_cost = to_decimal(shipping_cost_value)
      if shipping_cost.nil?
        Rails.logger.warn "[CpassDataSheetImporter] shipping_cost is nil after to_decimal. Row: #{row.to_h.inspect}"
        return
      end

      Rails.logger.info "[CpassDataSheetImporter] Final shipping_cost for row => #{shipping_cost}"

      shipment = Shipment.find_by(tracking_number: tracking_number)

      if shipment.nil?
        Rails.logger.info "[CpassDataSheetImporter] Shipment not found for tracking_number=#{tracking_number}."
        return
      end

      shipment.customer_international_shipping = shipping_cost
      shipment.save!
      Rails.logger.info "[CpassDataSheetImporter] Shipment updated successfully: shipment_id=#{shipment.id}, shipping_cost=#{shipping_cost}"
    end

    # 文字列をBigDecimalに変換
    def to_decimal(value)
      return nil if value.nil? || value.strip.empty?
      cleaned = value.gsub(/["',]/, "")
      BigDecimal(cleaned)
    rescue ArgumentError
      nil
    end
  end
end
