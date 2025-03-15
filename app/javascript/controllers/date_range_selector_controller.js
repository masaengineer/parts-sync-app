import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preset", "customRange", "startDate", "endDate", "form"];

  connect() {
    // 初期値がカスタムでない場合は日付範囲フィールドを非表示
    if (this.presetTarget.value !== "custom") {
      this.customRangeTarget.classList.add("hidden");
    }
  }

  // プリセット選択時の処理
  change() {
    const selectedValue = this.presetTarget.value;
    
    if (selectedValue === "custom") {
      // カスタム選択時は日付範囲フィールドを表示
      this.customRangeTarget.classList.remove("hidden");
    } else {
      // カスタム以外の場合は日付範囲フィールドを非表示
      this.customRangeTarget.classList.add("hidden");
      
      // 日付範囲を計算して設定
      const [startDate, endDate] = this.calculateDateRange(selectedValue);
      
      if (startDate) {
        this.startDateTarget.value = this.formatDate(startDate);
      }
      
      if (endDate) {
        this.endDateTarget.value = this.formatDate(endDate);
      }
      
      // フォームを自動送信
      this.formTarget.requestSubmit();
    }
  }

  // 日付範囲を計算
  calculateDateRange(preset) {
    const today = new Date();
    let startDate = new Date();
    let endDate = new Date();
    
    switch (preset) {
      case "last_90_days":
        startDate.setDate(today.getDate() - 90);
        break;
        
      case "today":
        // 開始日と終了日は同じ
        break;
        
      case "yesterday":
        startDate.setDate(today.getDate() - 1);
        endDate.setDate(today.getDate() - 1);
        break;
        
      case "this_week":
        // 今週の日曜日を開始日に
        const dayOfWeek = today.getDay();
        startDate.setDate(today.getDate() - dayOfWeek);
        break;
        
      case "last_week":
        // 先週の日曜日を開始日に
        const lastWeekDay = today.getDay();
        startDate.setDate(today.getDate() - lastWeekDay - 7);
        endDate.setDate(today.getDate() - lastWeekDay - 1);
        break;
        
      case "this_month":
        // 今月の1日を開始日に
        startDate.setDate(1);
        break;
        
      case "last_month":
        // 先月の1日を開始日に
        startDate.setDate(1);
        startDate.setMonth(today.getMonth() - 1);
        
        // 先月の最終日を終了日に
        endDate.setDate(0);
        break;
        
      case "this_year":
        // 今年の1月1日を開始日に
        startDate.setMonth(0);
        startDate.setDate(1);
        break;
        
      case "last_year":
        // 昨年の1月1日を開始日に
        startDate.setFullYear(today.getFullYear() - 1);
        startDate.setMonth(0);
        startDate.setDate(1);
        
        // 昨年の12月31日を終了日に
        endDate.setFullYear(today.getFullYear() - 1);
        endDate.setMonth(11);
        endDate.setDate(31);
        break;
    }
    
    return [startDate, endDate];
  }

  // 日付をYYYY-MM-DD形式に変換
  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  }
}