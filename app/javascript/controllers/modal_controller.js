import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ['modal'];

  connect() {
    console.log('modal controller connected');
    console.log('Modal element:', this.modalTarget);
    // dialogタグであるかを確認
    if (this.modalTarget.tagName === 'DIALOG') {
      this.modalTarget.showModal();
    } else {
      console.error('Modal target is not a DIALOG element:', this.modalTarget);
    }
  }

  close() {
    // 正しいモーダル要素を閉じる
    this.modalTarget.close();
  }
}
