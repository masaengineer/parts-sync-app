require 'rails_helper'

RSpec.describe Ebay::Transactions::BaseTransactionProcessor do
  let(:order) { instance_double('Order', id: 1) }
  let(:transaction) do
    {
      'transactionId' => 'tx1',
      'transactionType' => 'TEST',
      'amount' => { 'value' => '10.00' },
      'totalFeeBasisAmount' => { 'value' => '12.00' },
      'totalFeeAmount' => { 'value' => '2.00' }
    }
  end

  # テスト用の具象クラス
  let(:test_processor_class) do
    Class.new(described_class) do
      def transaction_type
        'test'
      end

      def process_transaction
        true
      end
    end
  end

  let(:processor) { test_processor_class.new(order, transaction) }

  describe '#process' do
    before do
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:error)
    end

    it 'トランザクションを処理して成功を返す' do
      expect(Rails.logger).to receive(:debug).at_least(:once)
      allow(processor).to receive(:log_success)
      expect(processor.process).to be true
    end

    context 'エラーが発生した場合' do
      before do
        allow(processor).to receive(:process_transaction).and_raise(StandardError, 'テスト例外')
      end

      it 'エラーをログに記録して例外を再スローする' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect { processor.process }.to raise_error(StandardError, 'テスト例外')
      end
    end
  end

  describe '#log_transaction_details' do
    before do
      allow(Rails.logger).to receive(:debug)
    end

    it 'トランザクション詳細をログに記録する' do
      expect(Rails.logger).to receive(:debug).at_least(4).times
      processor.send(:log_transaction_details)
    end
  end

  describe '#log_success' do
    before do
      allow(Rails.logger).to receive(:debug)
    end

    it '処理成功メッセージをログに記録する' do
      expect(Rails.logger).to receive(:debug).with('test transaction processing completed successfully')
      processor.send(:log_success)
    end
  end

  describe '#log_error' do
    before do
      allow(Rails.logger).to receive(:error)
    end

    it 'エラーメッセージをログに記録する' do
      exception = StandardError.new('テスト例外')
      # backtrace nilの場合の処理をモック
      allow(exception).to receive(:backtrace).and_return(nil)
      expect(Rails.logger).to receive(:error).with(/予期せぬエラー: StandardError/)
      # backtraceがnilの場合は2回目のerrorログ出力がない
      processor.send(:log_error, exception)
    end

    it 'backtrace付きのエラーをログに記録する' do
      exception = StandardError.new('テスト例外')
      allow(exception).to receive(:backtrace).and_return([ 'line1', 'line2' ])
      expect(Rails.logger).to receive(:error).with(/予期せぬエラー: StandardError/)
      expect(Rails.logger).to receive(:error).with("line1\nline2")
      processor.send(:log_error, exception)
    end
  end

  describe '#transaction_amount' do
    it 'トランザクション金額を返す' do
      expect(processor.send(:transaction_amount)).to eq(10.0)
    end
  end

  describe '#total_fee_basis_amount' do
    it '手数料ベース金額を返す' do
      expect(processor.send(:total_fee_basis_amount)).to eq(12.0)
    end
  end

  describe '#total_fee_amount' do
    it '手数料合計を返す' do
      expect(processor.send(:total_fee_amount)).to eq(2.0)
    end
  end

  describe '#record_exists?' do
    it 'PaymentFeeの存在チェックを行う' do
      params = { order: order, transaction_id: 'tx1' }
      allow(PaymentFee).to receive(:exists?).with(params).and_return(false)
      expect(PaymentFee).to receive(:exists?).with(params)
      processor.send(:record_exists?, params)
    end
  end

  describe '#log_duplicate_error' do
    before do
      allow(Rails.logger).to receive(:warn)
    end

    it '重複エラーをログに記録する' do
      expect(Rails.logger).to receive(:warn).with("重複エラー (テストタイプ): transaction_id=tx1")
      processor.send(:log_duplicate_error, 'テストタイプ')
    end
  end

  describe '#log_creation_error' do
    before do
      allow(Rails.logger).to receive(:error)
    end

    it '作成エラーをログに記録する' do
      exception = StandardError.new('作成失敗')
      allow(exception).to receive(:backtrace).and_return(nil)
      expect(Rails.logger).to receive(:error).with("Failed to create テストレコード: 作成失敗")
      # backtraceがnilの場合は2回目のerrorログ出力がない
      processor.send(:log_creation_error, 'テストレコード', exception)
    end

    it 'backtrace付きの作成エラーをログに記録する' do
      exception = StandardError.new('作成失敗')
      allow(exception).to receive(:backtrace).and_return([ 'line1', 'line2' ])
      expect(Rails.logger).to receive(:error).with("Failed to create テストレコード: 作成失敗")
      expect(Rails.logger).to receive(:error).with("line1\nline2")
      processor.send(:log_creation_error, 'テストレコード', exception)
    end
  end
end
