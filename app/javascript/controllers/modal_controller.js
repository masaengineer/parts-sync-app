import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['modal'];

  connect() {
    if (this.modalTarget.tagName === 'DIALOG') {
      this.modalTarget.showModal();

      // 外側クリックでモーダルを閉じるための処理
      this.handleOutsideClick = this.handleOutsideClick.bind(this);
      this.modalTarget.addEventListener('click', this.handleOutsideClick);

      // ESCキーの処理
      this.handleEscKey = this.handleEscKey.bind(this);
      document.addEventListener('keydown', this.handleEscKey);
    } else {
      console.error('Modal target is not a DIALOG element:', this.modalTarget);
    }
  }

  disconnect() {
    if (this.modalTarget) {
      this.modalTarget.removeEventListener('click', this.handleOutsideClick);
      document.removeEventListener('keydown', this.handleEscKey);
    }
  }

  handleOutsideClick(event) {
    // dialogの背景部分（modal-box以外）がクリックされた場合のみ閉じる
    const rect = this.modalTarget.getBoundingClientRect();
    const isInDialog = rect.top <= event.clientY && event.clientY <= rect.top + rect.height
      && rect.left <= event.clientX && event.clientX <= rect.left + rect.width;

    // dialogの中でクリックされた場合
    if (isInDialog) {
      if (event.target === this.modalTarget) {
        this.close();
      }
    }
  }

  handleEscKey(event) {
    if (event.key === 'Escape') {
      this.close();
    }
  }

  close() {
    this.modalTarget.close();
  }
}
