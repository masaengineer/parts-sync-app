import { Controller } from '@hotwired/stimulus';


export default class extends Controller {
  static targets = ['field', 'toggle'];

  connect() {
    
    this.fieldTarget.type = 'password';
    this.toggleTarget.dataset.slotValue = 'hide';
  }

  
  toggle() {
    const isVisible = this.fieldTarget.type === 'text';
    this.fieldTarget.type = isVisible ? 'password' : 'text';
    this.toggleTarget.dataset.slotValue = isVisible ? 'hide' : 'show';
  }
}
