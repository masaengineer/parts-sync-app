# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DataImports", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /import" do
    context "with no file selected" do
      it "redirects with an alert message" do
        post import_data_imports_path, params: { file: nil, import_type: "wisewill_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:alert]).to eq("ファイルを選択してください。")
      end
    end

    context "with invalid import type" do
      it "redirects with an error message" do
        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_wisewill_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "unknown_type" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:alert]).to eq("不明なインポートタイプです。")
      end
    end

    context "with valid Wisewill file" do
      it "imports data and redirects with success message" do
        # モックを使用してインポート処理をスキップ
        allow_any_instance_of(WisewillDataSheetImporter).to receive(:import).and_return(true)

        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_wisewill_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "wisewill_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:notice]).to eq("Wisewill委託分シートのインポートが完了しました。")
      end
    end

    context "with valid CPass file" do
      it "imports data and redirects with success message" do
        # モックを使用してインポート処理をスキップ
        allow_any_instance_of(CpassDataSheetImporter).to receive(:import).and_return(true)

        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_cpass_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "cpass_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:notice]).to eq("CPaSS委託分シートのインポートが完了しました。")
      end
    end

    context "with missing SKUs in Wisewill file" do
      it "handles the error and shows a specific error message" do
        # モックを使用してMissingSkusErrorを発生させる
        allow_any_instance_of(WisewillDataSheetImporter).to receive(:import).and_raise(
          WisewillDataSheetImporter::MissingSkusError.new("未登録のSKUが含まれています")
        )

        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_wisewill_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "wisewill_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:alert]).to eq("インポートエラー: 未登録のSKUが含まれています")
      end
    end

    context "with positive discount in CPass file" do
      it "handles the error and shows a specific error message" do
        # モックを使用してPositiveDiscountErrorを発生させる
        allow_any_instance_of(CpassDataSheetImporter).to receive(:import).and_raise(
          CpassDataSheetImporter::PositiveDiscountError.new("割引がマイナス値ではありません")
        )

        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_cpass_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "cpass_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:alert]).to eq("インポートエラー: 割引がマイナス値ではありません")
      end
    end

    context "with malformed CSV file" do
      it "handles the error and shows a user-friendly error message" do
        # モックを使用して一般エラーを発生させる
        allow_any_instance_of(WisewillDataSheetImporter).to receive(:import).and_raise(
          NoMethodError.new("undefined method `[]' for nil:NilClass")
        )

        file = fixture_file_upload(Rails.root.join('spec/fixtures/files/valid_wisewill_sheet.xlsx'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        post import_data_imports_path, params: { file: file, import_type: "wisewill_data_sheet" }

        expect(response).to redirect_to(sales_reports_path)
        expect(flash[:alert]).to eq("CSVファイルの形式が正しくないか、必要なデータが含まれていません。")
      end
    end
  end
end
