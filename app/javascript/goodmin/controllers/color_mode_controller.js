import { Controller } from "@hotwired/stimulus"

const DEFAULT_THEME = "auto"
const DEFAULT_THEME_LABEL = "Auto"

export default class extends Controller {
  static targets = ["toggle", "menuItem"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQueryListener = () => {
      if (this.theme === "auto") this.applyTheme("auto")
    }

    this.mediaQuery.addEventListener("change", this.mediaQueryListener)

    this.theme = this.normalizeTheme(this.storedTheme || DEFAULT_THEME)
    this.applyTheme(this.theme)
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.mediaQueryListener)
  }

  set({ params }) {
    this.theme = this.normalizeTheme(params.theme)
    window.localStorage.setItem("theme", this.theme)
    this.applyTheme(this.theme)
  }

  applyTheme(theme) {
    const resolvedTheme = theme === "auto" ? (this.mediaQuery.matches ? "dark" : "light") : theme
    document.documentElement.setAttribute("data-bs-theme", resolvedTheme)
    this.updateControls(theme)
  }

  updateControls(activeTheme) {
    this.menuItemTargets.forEach(menuItem => {
      const isActive = menuItem.dataset.theme === activeTheme
      menuItem.classList.toggle("active", isActive)
      menuItem.setAttribute("aria-pressed", String(isActive))
    })

    const activeItem = this.menuItemTargets.find(menuItem => menuItem.dataset.theme === activeTheme)
    this.toggleTarget.textContent = `Theme: ${activeItem?.textContent?.trim() || DEFAULT_THEME_LABEL}`
  }

  get storedTheme() {
    return window.localStorage.getItem("theme")
  }

  normalizeTheme(theme) {
    return ["light", "dark", DEFAULT_THEME].includes(theme) ? theme : DEFAULT_THEME
  }
}
