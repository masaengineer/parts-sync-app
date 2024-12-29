import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    // 5秒後に自動的に消える
    setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  dismiss() {
    this.element.classList.add('opacity-0');
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
