import { Controller } from "@hotwired/stimulus"
// JS
import {TourGuideClient} from "@sjmc11/tourguidejs/src/Tour"

// Connects to data-controller="tour"
export default class extends Controller {
  connect() {
    const tg = new TourGuideClient({})
    tg.start()
  }
}
