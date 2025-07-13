require "csv"

module CsvImporters
  class PostalDataSheetImporter
    TRACKING_NUMBER_COLUMN = 4  # E列（0-based index）
    DECISION_AMOUNT_COLUMN = 39 # AN列（0-based index）

    def initialize(csv_path, user)
      @csv_path = csv_path
      @user = user
    end

    def import
      Rails.logger.info "[PostalDataSheetImporter] インポート開始: #{@csv_path}"

      # Shift-JISからUTF-8に変換して読み込む
      csv_text = File.read(@csv_path, encoding: "Shift_JIS:UTF-8")
      csv = CSV.parse(csv_text, headers: false)

      Rails.logger.info "[PostalDataSheetImporter] CSVの行数: #{csv.size}"

      updated_count = 0
      not_found_count = 0

      ActiveRecord::Base.transaction do
        csv.each_with_index do |row, index|
          next if index == 0  # ヘッダー行をスキップ

          tracking_number_raw = row[TRACKING_NUMBER_COLUMN]
          decision_amount = row[DECISION_AMOUNT_COLUMN]

          next if tracking_number_raw.blank? || decision_amount.blank?

          # スペースを除去して追跡番号をクリーンアップ
          tracking_number = clean_tracking_number(tracking_number_raw)
          amount = parse_amount(decision_amount)

          Rails.logger.info "[PostalDataSheetImporter] 行 #{index + 1}: 追跡番号=#{tracking_number}, 決定金額=#{amount}"

          shipment = find_shipment_by_tracking_number(tracking_number)
          if shipment
            update_shipment_postal_data(shipment, amount)
            updated_count += 1
            Rails.logger.info "[PostalDataSheetImporter] 更新完了: Shipment ID=#{shipment.id}"
          else
            not_found_count += 1
            Rails.logger.warn "[PostalDataSheetImporter] 追跡番号が見つかりません: #{tracking_number}"
          end
        end
      end

      Rails.logger.info "[PostalDataSheetImporter] インポート完了: 更新=#{updated_count}件, 見つからない=#{not_found_count}件"

    rescue StandardError => e
      Rails.logger.error "[PostalDataSheetImporter] エラー発生: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    private

    def clean_tracking_number(raw_tracking_number)
      # "EN 382798993 JP" → "EN382798993JP" のようにスペースを除去
      raw_tracking_number.to_s.gsub(/\s+/, "")
    end

    def parse_amount(amount_str)
      amount_str.to_f
    end

    def find_shipment_by_tracking_number(tracking_number)
      # 完全一致で検索
      shipment = Shipment.find_by(tracking_number: tracking_number)

      # 見つからない場合、既存の追跡番号からスペースを除去して比較
      unless shipment
        Shipment.where.not(tracking_number: [ nil, "" ]).find do |s|
          clean_tracking_number(s.tracking_number) == tracking_number
        end
      end

      shipment
    end

    def update_shipment_postal_data(shipment, amount)
      shipment.update!(
        customer_international_shipping: amount
      )
    end
  end
end
