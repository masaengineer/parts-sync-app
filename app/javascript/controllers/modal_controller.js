import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'modal',
    'backdrop',
    'priceAdjustmentForm',
    'adjustmentFormContent',
    'skuCodeDisplay',
    'toggleFormVisibility',
  ];

  connect() {
    if (this.modalTarget.tagName === 'DIALOG') {
      this.modalTarget.showModal();

      this.backdropTarget.addEventListener(
        'click', this.closeOnBackdropClick.bind(this));

      this.handleEscKey = this.handleEscKey.bind(this);
      document.addEventListener('keydown', this.handleEscKey);

      this.handleScrollTop = this.scrollToTop.bind(this);
      document.addEventListener(
        'price-adjustment:scroll-top',
        this.handleScrollTop
      );
    } else {
      console.error('Modal target is not a DIALOG element:', this.modalTarget);
    }
  }

  disconnect() {
    if (this.modalTarget) {
      if (this.hasBackdropTarget) {
        this.backdropTarget.removeEventListener(
          'click', this.closeOnBackdropClick
        );
      }
      document.removeEventListener('keydown', this.handleEscKey);
      document.removeEventListener(
        'price-adjustment:scroll-top',
        this.handleScrollTop
      );
    }
  }

  closeOnBackdropClick(event) {
    // イベントの伝播を停止して、モーダル自体のクリックイベントを防ぐ
    event.stopPropagation();
    this.close();
  }

  handleEscKey(event) {
    if (event.key === 'Escape') {
      this.close();
    }
  }

  close() {
    this.modalTarget.close();
  }

  prepareAdjustmentForm(event) {
    this.priceAdjustmentFormTarget.classList.remove('hidden');

    this.adjustmentFormContentTarget.innerHTML =
      '<div class="flex justify-center p-4"><span class="loading loading-spinner loading-md"></span></div>';

    setTimeout(() => {
      this.priceAdjustmentFormTarget.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
      });
    }, 100);
  }

  closePriceAdjustmentForm() {
    this.priceAdjustmentFormTarget.classList.add('hidden');
  }

  toggleFormVisibilityTargetConnected() {
    if (this.hasToggleFormVisibilityTarget) {
      this.priceAdjustmentFormTarget.classList.add('hidden');

      this.scrollToTop();
    }
  }

  scrollToTop() {
    if (this.modalTarget) {
      const modalBox = this.modalTarget.querySelector('.modal-box');
      if (modalBox) {
        modalBox.scrollTop = 0;
      }
    }
  }
}
