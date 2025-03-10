class DataImportsController < ApplicationController
  def import
    file = params[:file]
    import_type = params[:import_type]

    if file.blank?
      redirect_to sales_reports_path, alert: "ファイルを選択してください。" and return
    end

    begin
      case import_type
      when "wisewill_data_sheet"
        WisewillDataSheetImporter.new(file.path, current_user).import
        flash[:notice] = "Wisewill委託分シートのインポートが完了しました。"
      when "cpass_data_sheet"
        CpassDataSheetImporter.new(file.path, current_user).import
        flash[:notice] = "CPaSS委託分シートのインポートが完了しました。"
      else
        flash[:alert] = "不明なインポートタイプです。"
      end
    rescue WisewillDataSheetImporter::MissingOrderNumbersError => e
      flash[:alert] = "インポートエラー: #{e.message}"
    rescue CpassDataSheetImporter::PositiveDiscountError => e
      flash[:alert] = "インポートエラー: #{e.message}"
    rescue StandardError => e
      flash[:alert] = case e.message
      when /undefined method.*nil/
        "CSVファイルの形式が正しくないか、必要なデータが含まれていません。"
      when /CSVファイルの処理中/
        e.message
      else
        "予期せぬエラーが発生しました: #{e.message}"
      end
    end

    redirect_to sales_reports_path
  end
end
