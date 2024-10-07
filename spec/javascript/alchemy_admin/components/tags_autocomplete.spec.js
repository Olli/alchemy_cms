import { renderComponent } from "./component.helper"

// import jquery and append it to the window object
import jQuery from "jquery"
globalThis.$ = jQuery
globalThis.jQuery = jQuery

import "alchemy_admin/components/tags_autocomplete"
import("select2")

describe("alchemy-tags-autocomplete", () => {
  /**
   *
   * @type {HTMLElement | undefined}
   */
  let component = undefined

  beforeEach(() => {
    const html = `
      <alchemy-tags-autocomplete>
        <input type="text">
      </alchemy-tags-autocomplete>
    `
    component = renderComponent("alchemy-tags-autocomplete", html)
  })

  it("should render the input field", () => {
    expect(component.getElementsByTagName("input")[0]).toBeInstanceOf(
      HTMLElement
    )
  })

  it("should initialize Select2", () => {
    expect(
      component.getElementsByClassName("select2-container").length
    ).toEqual(1)
  })
})
