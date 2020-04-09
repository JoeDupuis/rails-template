import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["alert"]
	connect() {
		const $btn = document.createElement("button");
		$btn.innerHTML = "&times;";
		$btn.classList.add("close");
		$btn.setAttribute("aria-hidden", true);
		$btn.addEventListener("click", this.dismiss.bind(this));

		// tag.button(type: "button", class: "close", 'aria-hidden': true, 'data-action': "click->alert#dismiss") { raw "&times;" },
		this.element.prepend($btn);
	}

	dismiss(event) {
		this.element.remove();
	}
}
