import { Controller } from "@hotwired/stimulus"

const DEFAULT_THEME = "auto"
const VALID_THEMES = ["light", "dark", DEFAULT_THEME]
const THEME_LABELS = {
  light: "Light",
  dark: "Dark",
  auto: "Auto"
}

export default class extends Controller {
  static targets = ["toggle", "toggleIcon", "menuItem"]

  connect() {
    this.mediaQuery = typeof window.matchMedia === "function"
      ? window.matchMedia("(prefers-color-scheme: dark)")
      : null
    this.mediaQueryListener = () => {
      if (this.theme === "auto") this.applyTheme("auto")
    }

    this.mediaQuery?.addEventListener?.("change", this.mediaQueryListener)

    this.theme = this.normalizeTheme(this.storedTheme || DEFAULT_THEME)
    this.applyTheme(this.theme)
  }

  disconnect() {
    this.mediaQuery?.removeEventListener?.("change", this.mediaQueryListener)
  }

  set({ params }) {
    this.theme = this.normalizeTheme(params.theme)
    this.storeTheme(this.theme)
    this.applyTheme(this.theme)
  }

  applyTheme(theme) {
    const resolvedTheme = this.resolveTheme(theme)
    document.documentElement.setAttribute("data-bs-theme", resolvedTheme)
    this.updateControls(theme)
  }

  updateControls(activeTheme) {
    if (!this.hasMenuItemTarget || !this.hasToggleTarget || !this.hasToggleIconTarget) return

    this.menuItemTargets.forEach(menuItem => {
      const isActive = menuItem.dataset.theme === activeTheme
      menuItem.classList.toggle("active", isActive)
      menuItem.setAttribute("aria-pressed", String(isActive))
    })

    const activeItem = this.menuItemTargets.find(menuItem => menuItem.dataset.theme === activeTheme)
    const activeThemeLabel = THEME_LABELS[activeTheme] || THEME_LABELS[DEFAULT_THEME]
    const activeIcon = activeItem?.querySelector("[data-color-mode-icon]")?.cloneNode(true)

    if (activeIcon) this.toggleIconTarget.replaceChildren(activeIcon)

    this.toggleTarget.setAttribute("aria-label", `Color theme: ${activeThemeLabel}`)
    this.toggleTarget.setAttribute("title", `Color theme: ${activeThemeLabel}`)
  }

  get storedTheme() {
    try {
      return window.localStorage.getItem("theme")
    } catch (error) {
      console.warn("Goodmin color mode preference could not be read.", error)
      return null
    }
  }

  normalizeTheme(theme) {
    return VALID_THEMES.includes(theme) ? theme : DEFAULT_THEME
  }

  resolveTheme(theme) {
    if (theme === "auto") return this.systemTheme()

    return theme
  }

  systemTheme() {
    if (!this.mediaQuery) return "light"

    return this.mediaQuery.matches ? "dark" : "light"
  }

  storeTheme(theme) {
    try {
      window.localStorage.setItem("theme", theme)
    } catch (error) {
      console.warn("Goodmin color mode preference could not be stored.", error)
    }
  }
}
