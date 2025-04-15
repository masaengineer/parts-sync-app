# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvImporters::CpassDataSheetImporter do
  let(:user) { create(:user) }
  let(:csv_path) { Rails.root.join('spec/fixtures/files/cpass_sample.csv') }
  let(:importer) { described_class.new(csv_path, user) }

  # CSVのフィクスチャファイルを作成するためのhelperメソッド
  def create_csv_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(content) }
  end

  # テスト後のクリーンアップ
  after do
    FileUtils.rm_f(csv_path)
    FileUtils.rm_f(Rails.root.join('spec/fixtures/files/cpass_invalid.csv'))
  end

  describe '#import' do
    context '有効なCSVデータの場合' do
      before do
        # テスト用の出荷情報を作成
        create(:shipment, tracking_number: 'TRACK001', customer_international_shipping: nil)
        create(:shipment, tracking_number: 'TRACK002', customer_international_shipping: nil)

        # 有効なCSVファイルを作成
        valid_csv_content = <<~CSV
          注文番号,金額（円）,ご請求金額（円）,還元金額（円）
          TRACK001,1000,800,-200
          TRACK002,2000,2000,0
        CSV
        create_csv_file(csv_path, valid_csv_content)
      end

      it '各行に対して送料情報を更新すること' do
        importer.import

        shipment1 = Shipment.find_by(tracking_number: 'TRACK001')
        shipment2 = Shipment.find_by(tracking_number: 'TRACK002')

        # 還元金額が負の場合は金額（円）が設定される
        expect(shipment1.customer_international_shipping).to eq(1000)
        # 還元金額が0の場合はご請求金額（円）が設定される
        expect(shipment2.customer_international_shipping).to eq(2000)
      end
    end

    context '還元金額が正の値の場合' do
      before do
        create(:shipment, tracking_number: 'TRACK001')

        invalid_csv_content = <<~CSV
          注文番号,金額（円）,ご請求金額（円）,還元金額（円）
          TRACK001,1000,800,200
        CSV
        create_csv_file(Rails.root.join('spec/fixtures/files/cpass_invalid.csv'), invalid_csv_content)
      end

      it 'PositiveDiscountErrorをスローすること' do
        invalid_importer = described_class.new(Rails.root.join('spec/fixtures/files/cpass_invalid.csv'), user)
        expect { invalid_importer.import }.to raise_error(CsvImporters::CpassDataSheetImporter::PositiveDiscountError)
      end
    end

    context '存在しないトラッキング番号の場合' do
      before do
        invalid_csv_content = <<~CSV
          注文番号,金額（円）,ご請求金額（円）,還元金額（円）
          NONEXISTENT,1000,800,-200
        CSV
        create_csv_file(csv_path, invalid_csv_content)
      end

      it '送料を更新しないこと' do
        expect { importer.import }.not_to change { Shipment.where.not(customer_international_shipping: nil).count }
      end
    end
  end

  describe 'プライベートメソッド' do
    describe '#to_decimal' do
      it '文字列をBigDecimalに変換すること' do
        expect(importer.send(:to_decimal, '1000')).to eq(BigDecimal('1000'))
      end

      it 'カンマ区切りの数値文字列を処理すること' do
        expect(importer.send(:to_decimal, '1,000')).to eq(BigDecimal('1000'))
      end

      it '空文字列に対してnilを返すこと' do
        expect(importer.send(:to_decimal, '')).to be_nil
      end

      it 'nil値に対してnilを返すこと' do
        expect(importer.send(:to_decimal, nil)).to be_nil
      end

      it '無効な数値に対してnilを返すこと' do
        expect(importer.send(:to_decimal, 'invalid')).to be_nil
      end
    end
  end
end
