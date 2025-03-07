import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    console.log('modal controller connected');
    this.element.showModal()
  }

  close() {
    this.element.close()
  }
}
