import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preset", "customRange", "startDate", "endDate", "form"];

  connect() {
    
    if (this.presetTarget.value !== "custom") {
      this.customRangeTarget.classList.add("hidden");
    }
  }

  
  change() {
    const selectedValue = this.presetTarget.value;
    
    if (selectedValue === "custom") {
      
      this.customRangeTarget.classList.remove("hidden");
    } else {
      
      this.customRangeTarget.classList.add("hidden");
      
      
      const [startDate, endDate] = this.calculateDateRange(selectedValue);
      
      if (startDate) {
        this.startDateTarget.value = this.formatDate(startDate);
      }
      
      if (endDate) {
        this.endDateTarget.value = this.formatDate(endDate);
      }
      
      
      this.formTarget.requestSubmit();
    }
  }

  
  calculateDateRange(preset) {
    const today = new Date();
    let startDate = new Date();
    let endDate = new Date();
    
    switch (preset) {
      case "last_90_days":
        startDate.setDate(today.getDate() - 90);
        break;
        
      case "today":
        
        break;
        
      case "yesterday":
        startDate.setDate(today.getDate() - 1);
        endDate.setDate(today.getDate() - 1);
        break;
        
      case "this_week":
        
        const dayOfWeek = today.getDay();
        startDate.setDate(today.getDate() - dayOfWeek);
        break;
        
      case "last_week":
        
        const lastWeekDay = today.getDay();
        startDate.setDate(today.getDate() - lastWeekDay - 7);
        endDate.setDate(today.getDate() - lastWeekDay - 1);
        break;
        
      case "this_month":
        
        startDate.setDate(1);
        break;
        
      case "last_month":
        
        startDate.setDate(1);
        startDate.setMonth(today.getMonth() - 1);
        
        
        endDate.setDate(0);
        break;
        
      case "this_year":
        
        startDate.setMonth(0);
        startDate.setDate(1);
        break;
        
      case "last_year":
        
        startDate.setFullYear(today.getFullYear() - 1);
        startDate.setMonth(0);
        startDate.setDate(1);
        
        
        endDate.setFullYear(today.getFullYear() - 1);
        endDate.setMonth(11);
        endDate.setDate(31);
        break;
    }
    
    return [startDate, endDate];
  }

  
  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  }
}