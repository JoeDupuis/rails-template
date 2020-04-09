import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["toggle"];

  connect() {
    // Create the DOM element for the toggle button.
    const $toggle = document.createElement("input");
    $toggle.type = "checkbox";
    $toggle.classList.add("menu__close");
    $toggle.setAttribute("data-target", "menu.toggle");
    $toggle.addEventListener("click", this.toggle.bind(this));

    // So it is focused before the menu items.
    this.element.prepend($toggle);

    // Collapse at start
    this.setValue(true);
  }

  toggle() {
    const $toggle = this.toggleTarget;
    this.setValue($toggle.checked);
  }

  setValue(collapsed) {
    const $toggle = this.toggleTarget;
    $toggle.checked = collapsed;

    if (collapsed) {
      this.element.classList.add("is-collapsed");
    }
    else {
      this.element.classList.remove("is-collapsed");
    }
  }
}
