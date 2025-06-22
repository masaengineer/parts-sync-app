class Admin::SyncController < ApplicationController
  before_action :authenticate_user!
  
  def show
    @recent_logs = read_recent_logs
    @is_running = sync_running?
  end
  
  def create
    if sync_running?
      redirect_to admin_sync_path, alert: "同期が既に実行中です"
      return
    end
    
    # バックグラウンドで同期実行
    log_file = Rails.root.join('log', 'manual_sync.log')
    
    # ログファイルをクリア
    File.write(log_file, '') if File.exist?(log_file)
    
    pid = spawn(
      { 'RAILS_ENV' => Rails.env },
      "cd #{Rails.root} && bundle exec rake ebay:sync_all",
      out: log_file.to_s,
      err: [:child, :out]
    )
    
    Process.detach(pid)
    
    Rails.logger.info "手動同期開始 - PID: #{pid}, ユーザー: #{current_user.email}"
    
    redirect_to admin_sync_path, notice: "同期を開始しました（PID: #{pid}）"
  end
  
  private
  
  def sync_running?
    lockfile_path = Rails.root.join('tmp', 'ebay_sync.lock')
    return false unless File.exist?(lockfile_path)
    
    begin
      pid = File.read(lockfile_path).strip.to_i
      # プロセスが存在するかチェック
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      # プロセスが存在しない場合はロックファイルを削除
      File.delete(lockfile_path)
      false
    rescue ArgumentError
      # 無効なPIDの場合はロックファイルを削除
      File.delete(lockfile_path)
      false
    end
  end
  
  def read_recent_logs
    log_files = [
      Rails.root.join('log', 'manual_sync.log'),
      Rails.root.join('log', Rails.env + '.log')
    ]
    
    recent_logs = []
    
    log_files.each do |log_file|
      next unless File.exist?(log_file)
      
      begin
        # 最新の100行を取得
        lines = File.readlines(log_file).last(100)
        
        # eBay同期関連のログのみ抽出
        ebay_logs = lines.select do |line|
          line.include?('eBay') || 
          line.include?('同期') ||
          line.include?('sync') ||
          line.include?('EBAY')
        end
        
        recent_logs.concat(ebay_logs.last(50))
      rescue => e
        Rails.logger.error "ログ読み取りエラー: #{e.message}"
      end
    end
    
    # 時系列でソート（簡易版）
    recent_logs.uniq.last(30)
  end
end