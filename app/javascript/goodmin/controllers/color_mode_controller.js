import { Controller } from "@hotwired/stimulus"

const DEFAULT_THEME = "auto"
const VALID_THEMES = ["light", "dark", DEFAULT_THEME]
const THEME_LABELS = {
  light: "Light",
  dark: "Dark",
  auto: "Auto"
}
const THEME_ICONS = {
  light: `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-sun-fill" viewBox="0 0 16 16">
      <path d="M8 4a4 4 0 1 0 0 8 4 4 0 0 0 0-8"/>
      <path d="M8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0m0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13m8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 16 8M3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8m10.657-5.657a.5.5 0 0 1 0 .707L12.243 4.464a.5.5 0 1 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0m-9.9 9.9a.5.5 0 0 1 0 .707L2.343 14.364a.5.5 0 1 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0m9.9 2.121a.5.5 0 0 1-.707 0L11.536 12.95a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707m-9.9-9.9a.5.5 0 0 1-.707 0L1.636 3.05a.5.5 0 1 1 .707-.707L3.757 3.757a.5.5 0 0 1 0 .707"/>
    </svg>
  `,
  dark: `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-moon-stars-fill" viewBox="0 0 16 16">
      <path d="M6 .278a.77.77 0 0 1 .08.858A7.2 7.2 0 0 0 5.8 2.37c0 4.277 3.136 7.73 7 7.73q.537 0 1.044-.095a.77.77 0 0 1 .855.083.79.79 0 0 1 .242.86A8.35 8.35 0 0 1 7.278 16C3.267 16 0 12.726 0 8.687 0 5.418 2.114 2.66 5.124 1.272A.77.77 0 0 1 6 .278"/>
      <path d="M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387a.217.217 0 0 1 0 .412l-1.162.387a1.73 1.73 0 0 0-1.097 1.097l-.387 1.162a.217.217 0 0 1-.412 0l-.387-1.162A1.73 1.73 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387a1.73 1.73 0 0 0 1.097-1.097zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.16 1.16 0 0 0-.732.732l-.258.774a.145.145 0 0 1-.274 0l-.258-.774a1.16 1.16 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774-.258a1.16 1.16 0 0 0 .732-.732z"/>
    </svg>
  `,
  auto: `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-circle-half" viewBox="0 0 16 16">
      <path d="M8 15A7 7 0 1 0 8 1z"/>
      <path d="M8 0a8 8 0 1 1 0 16z"/>
    </svg>
  `
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
    try {
      window.localStorage.setItem("theme", this.theme)
    } catch (_) {}
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

    const activeThemeLabel = THEME_LABELS[activeTheme] || THEME_LABELS[DEFAULT_THEME]
    this.toggleIconTarget.innerHTML = THEME_ICONS[activeTheme] || THEME_ICONS[DEFAULT_THEME]
    this.toggleTarget.setAttribute("aria-label", `Color theme: ${activeThemeLabel}`)
    this.toggleTarget.setAttribute("title", `Color theme: ${activeThemeLabel}`)
  }

  get storedTheme() {
    try {
      return window.localStorage.getItem("theme")
    } catch (_) {
      return null
    }
  }

  normalizeTheme(theme) {
    return VALID_THEMES.includes(theme) ? theme : DEFAULT_THEME
  }

  resolveTheme(theme) {
    if (theme === "auto") return this.mediaQuery?.matches ? "dark" : "light"

    return theme
  }
}
