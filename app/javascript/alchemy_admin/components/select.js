class Select extends HTMLSelectElement {
  connectedCallback() {
    this.classList.add("alchemy_selectbox")

    $(this).select2({
      minimumResultsForSearch: 7,
      dropdownAutoWidth: true
    })
  }
}

customElements.define("alchemy-select", Select, { extends: "select" })
