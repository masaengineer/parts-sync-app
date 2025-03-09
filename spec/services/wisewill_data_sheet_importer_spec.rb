# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WisewillDataSheetImporter do
  let(:user) { create(:user) }
  let(:csv_path) { Rails.root.join('spec/fixtures/files/wisewill_sample.csv') }
  let(:importer) { described_class.new(csv_path, user) }

  # CSVのフィクスチャファイルを作成するためのhelperメソッド
  def create_csv_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |f| f.write(content) }
  end

  # テスト後のクリーンアップ
  after do
    FileUtils.rm_f(csv_path)
    FileUtils.rm_f(Rails.root.join('spec/fixtures/files/wisewill_invalid.csv'))
  end

  describe '#import' do
    context '有効なCSVデータの場合' do
      before do
        # テスト用の注文と出荷情報を作成
        order1 = create(:order, user: user, order_number: 'ORDER001')
        create(:shipment, order: order1, tracking_number: 'TRACK001')

        order2 = create(:order, user: user, order_number: 'ORDER002')
        create(:shipment, order: order2, tracking_number: 'TRACK002')

        # 有効なCSVファイルを作成
        valid_csv_content = <<~CSV
          order_number,sku_code,purchase_price
          ORDER001,SKU001,1000
          ORDER002,SKU002,2000
        CSV
        create_csv_file(csv_path, valid_csv_content)
      end

      it '各行に対して調達レコードを作成すること' do
        expect { importer.import }.to change(Procurement, :count).by(2)

        # 調達レコードが正しく作成されていることを確認
        procurement1 = Procurement.find_by(purchase_price: 1000)
        procurement2 = Procurement.find_by(purchase_price: 2000)

        expect(procurement1).to be_present
        expect(procurement2).to be_present

        # 関連する注文を確認
        order1 = Order.find_by(order_number: 'ORDER001')
        expect(procurement1.order_id).to eq(order1.id)

        order2 = Order.find_by(order_number: 'ORDER002')
        expect(procurement2.order_id).to eq(order2.id)
      end
    end

    context '購入価格が欠損している場合' do
      before do
        # テスト用の注文と出荷情報を作成
        order = create(:order, user: user, order_number: 'ORDER001')
        create(:shipment, order: order, tracking_number: 'TRACK001')

        # 購入価格が空のCSVファイルを作成
        invalid_csv_content = <<~CSV
          order_number,sku_code,purchase_price
          ORDER001,SKU001,
        CSV
        create_csv_file(Rails.root.join('spec/fixtures/files/wisewill_invalid.csv'), invalid_csv_content)
      end

      it 'MissingPurchasePriceErrorをスローすること' do
        invalid_importer = described_class.new(Rails.root.join('spec/fixtures/files/wisewill_invalid.csv'), user)
        expect { invalid_importer.import }.to raise_error(WisewillDataSheetImporter::MissingPurchasePriceError)
      end
    end

    context '存在しないオーダー番号の場合' do
      before do
        # 存在しないオーダー番号を含むCSVファイルを作成
        invalid_csv_content = <<~CSV
          order_number,sku_code,purchase_price
          NONEXISTENT,SKU001,1000
        CSV
        create_csv_file(csv_path, invalid_csv_content)
      end

      it '存在しないオーダー番号に対して調達レコードを作成しないこと' do
        expect { importer.import }.to raise_error(WisewillDataSheetImporter::OrderNotFoundError)
      end
    end

    context 'SKUが欠損している場合' do
      before do
        # テスト用の注文と出荷情報を作成
        order = create(:order, user: user, order_number: 'ORDER001')
        create(:shipment, order: order, tracking_number: 'TRACK001')

        # SKUが空のCSVファイルを作成
        invalid_csv_content = <<~CSV
          order_number,sku_code,purchase_price
          ORDER001,,1000
        CSV
        create_csv_file(Rails.root.join('spec/fixtures/files/wisewill_invalid.csv'), invalid_csv_content)
      end

      it 'MissingSkusErrorをスローすること' do
        invalid_importer = described_class.new(Rails.root.join('spec/fixtures/files/wisewill_invalid.csv'), user)
        expect { invalid_importer.import }.to raise_error(WisewillDataSheetImporter::MissingSkusError)
      end
    end

    context '既存の調達レコードがある場合' do
      before do
        # テスト用の注文と出荷情報を作成
        order = create(:order, user: user, order_number: 'ORDER001')
        shipment = create(:shipment, order: order, tracking_number: 'TRACK001')

        # 既存の調達レコードを作成
        create(:procurement, order: order, purchase_price: 500)

        # CSVファイルを作成（購入価格が異なる）
        csv_content = <<~CSV
          order_number,sku_code,purchase_price
          ORDER001,SKU001,1000
        CSV
        create_csv_file(csv_path, csv_content)
      end

      it '既存の調達レコードを更新すること' do
        expect { importer.import }.not_to change(Procurement, :count)

        # 調達レコードが更新されていることを確認
        procurement = Procurement.last
        expect(procurement.purchase_price.to_i).to eq(1000)
      end
    end
  end

  describe 'プライベートメソッド' do
    describe '#to_decimal' do
      it '文字列をBigDecimalに変換すること' do
        # privateメソッドをテストするには、sendメソッドを使用
        expect(importer.send(:to_decimal, '1000').to_i).to eq(1000)
      end

      it 'カンマ区切りの数値文字列を処理すること' do
        expect(importer.send(:to_decimal, '1,000').to_i).to eq(1000)
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
