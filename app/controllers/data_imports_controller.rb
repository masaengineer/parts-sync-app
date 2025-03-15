class DataImportsController < ApplicationController
  def import
    file = params[:file]
    import_type = params[:import_type]

    if file.blank?
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "ファイルを選択してください。"
          render turbo_stream: [
            turbo_stream.replace(
              "csv_import",
              partial: "sales_reports/csv_import_form",
              locals: { flash: flash }
            ),
            turbo_stream.replace(
              "flash",
              partial: "shared/flash_messages",
              locals: { flash: flash }
            ),
            turbo_stream.update(
              "import_result_script",
              "<script>
                document.dispatchEvent(new CustomEvent('turbo:frame-load', { detail: { frame: document.getElementById('csv_import') } }));
              </script>"
            )
          ]
        end
        format.html { redirect_to sales_reports_path, alert: "ファイルを選択してください。" }
      end
      return
    end

    begin
      case import_type
      when "wisewill_data_sheet"
        WisewillDataSheetImporter.new(file.path, current_user).import
        flash_message = "Wisewill委託分シートのインポートが完了しました。"
        flash_type = :notice
      when "cpass_data_sheet"
        CpassDataSheetImporter.new(file.path, current_user).import
        flash_message = "CPaSS委託分シートのインポートが完了しました。"
        flash_type = :notice
      else
        flash_message = "不明なインポートタイプです。"
        flash_type = :alert
      end
    rescue WisewillDataSheetImporter::MissingOrderNumbersError => e
      flash_message = "インポートエラー: #{e.message}"
      flash_type = :alert
    rescue CpassDataSheetImporter::PositiveDiscountError => e
      flash_message = "インポートエラー: #{e.message}"
      flash_type = :alert
    rescue StandardError => e
      flash_message = case e.message
      when /undefined method.*nil/
        "CSVファイルの形式が正しくないか、必要なデータが含まれていません。"
      when /CSVファイルの処理中/
        e.message
      else
        "予期せぬエラーが発生しました: #{e.message}"
      end
      flash_type = :alert
    end

    respond_to do |format|
      format.turbo_stream do
        flash.now[flash_type] = flash_message
        render turbo_stream: [
          turbo_stream.replace(
            "csv_import",
            partial: "sales_reports/csv_import_form",
            locals: { flash: flash }
          ),
          turbo_stream.replace(
            "flash",
            partial: "shared/flash_messages",
            locals: { flash: flash }
          ),
          turbo_stream.update(
            "import_result_script",
            "<script>
              document.dispatchEvent(new CustomEvent('turbo:frame-load', { detail: { frame: document.getElementById('csv_import') } }));
              document.getElementById('csvImportModal').close();
            </script>"
          )
        ]
      end
      format.html do
        flash[flash_type] = flash_message
        redirect_to sales_reports_path
      end
    end
  end
end
