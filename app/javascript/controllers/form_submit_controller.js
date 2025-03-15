import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['buttonText', 'spinner', 'submitButton'];

  connect() {
    // Turboフレームのイベントを監視
    document.addEventListener(
      'turbo:submit-start',
      this.handleSubmitStart.bind(this)
    );
    document.addEventListener(
      'turbo:submit-end',
      this.handleSubmitEnd.bind(this)
    );
    document.addEventListener(
      'turbo:before-fetch-request',
      this.handleBeforeFetch.bind(this)
    );
    document.addEventListener(
      'turbo:before-fetch-response',
      this.handleBeforeFetchResponse.bind(this)
    );
    document.addEventListener(
      'turbo:frame-load',
      this.handleFrameLoad.bind(this)
    );
  }

  disconnect() {
    // イベントリスナーを削除
    document.removeEventListener('turbo:submit-start', this.handleSubmitStart);
    document.removeEventListener('turbo:submit-end', this.handleSubmitEnd);
    document.removeEventListener(
      'turbo:before-fetch-request',
      this.handleBeforeFetch
    );
    document.removeEventListener(
      'turbo:before-fetch-response',
      this.handleBeforeFetchResponse
    );
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  submit(event) {
    // 送信ボタンがクリックされたとき
    this.showLoadingState();

    // フォームを取得してsubmitを呼び出す
    const formId = event.currentTarget.getAttribute('form');
    if (formId) {
      const form = document.getElementById(formId);
      if (form) {
        form.requestSubmit();
      }
    }
  }

  showLoadingState() {
    // ローディング状態の表示
    if (this.hasButtonTextTarget && this.hasSpinnerTarget) {
      this.buttonTextTarget.classList.add('hidden');
      this.spinnerTarget.classList.remove('hidden');
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
    }
  }

  resetLoadingState() {
    // ローディング状態の解除
    if (this.hasButtonTextTarget && this.hasSpinnerTarget) {
      this.buttonTextTarget.classList.remove('hidden');
      this.spinnerTarget.classList.add('hidden');
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
    }
  }

  handleSubmitStart(event) {
    // フォーム送信開始時の処理
    if (event.target && event.target.id === 'csv-import-form') {
      this.showLoadingState();
    }
  }

  handleSubmitEnd(event) {
    // フォーム送信完了時の処理
    if (event.target && event.target.id === 'csv-import-form') {
      this.resetLoadingState();
    }
  }

  handleFrameLoad(event) {
    // フレームロード完了時の処理
    const frame = event.target;
    if (frame && frame.id === 'csv_import') {
      this.resetLoadingState();
    }
  }

  handleBeforeFetch(event) {
    // フェッチ開始前の処理
    const frame = event.target;
    if (frame && frame.id === 'csv_import') {
      this.showLoadingState();
    }
  }

  handleBeforeFetchResponse(event) {
    // レスポンス取得後の処理
    // ここでは特に何もしない
    // turbo:submit-endで処理する
  }

  disableSubmit() {
    const buttons = this.element.querySelectorAll(
      "button, input[type='submit']"
    );
    buttons.forEach((button) => {
      button.disabled = true;
      if (button.classList.contains('btn-primary')) {
        button.classList.add('loading');
      }
    });

    const inputs = this.element.querySelectorAll('input, select, textarea');
    inputs.forEach((input) => {
      input.readOnly = true;
    });

    this.element.classList.add('opacity-70');

    const modalController =
      this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller="modal"]'),
        'modal'
      );

    if (modalController && modalController.priceAdjustmentFormTarget) {
      modalController.priceAdjustmentFormTarget.classList.add('hidden');
    }
  }
}
