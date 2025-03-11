import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["buttonText", "spinner"]

  submit(event) {
    this.buttonTextTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
  }
}
