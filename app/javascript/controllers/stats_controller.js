import { Controller } from "@hotwired/stimulus"
import $ from 'jquery'

export default class extends Controller {
  static values = { width: String }

  connect() {
    $(this.element).animate({ width: this.widthValue + '%' }, 700).removeClass('t-item--hidden').css("display", "block");
  }
}
