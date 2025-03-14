import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["buttonText", "spinner"]

  submit(event) {
    this.buttonTextTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
  }

  disableSubmit() {
    const buttons = this.element.querySelectorAll("button, input[type='submit']")
    buttons.forEach(button => {
      button.disabled = true
      if (button.classList.contains("btn-primary")) {
        button.classList.add("loading")
      }
    })

    const inputs = this.element.querySelectorAll("input, select, textarea")
    inputs.forEach(input => {
      input.readOnly = true
    })

    this.element.classList.add("opacity-70")

    const modalController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="modal"]'),
      "modal"
    )

    if (modalController && modalController.priceAdjustmentFormTarget) {
      modalController.priceAdjustmentFormTarget.classList.add("hidden")
    }
  }
}
