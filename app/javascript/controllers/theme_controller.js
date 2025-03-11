import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['toggle'];

  connect() {
    if (this.hasToggleTarget) {
      this.toggleTarget.addEventListener('change', this.toggleTheme.bind(this));
    }
  }

  disconnect() {
    if (this.hasToggleTarget) {
      this.toggleTarget.removeEventListener(
        'change',
        this.toggleTheme.bind(this)
      );
    }
  }

  toggleTheme(event) {
    const html = document.querySelector('html');
    html.setAttribute('data-theme', event.target.checked ? 'dark' : 'light');
  }
}
