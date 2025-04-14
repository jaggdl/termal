import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["darkModeCheckbox"]

  connect() {
    this.updateTheme()
    
    // Watch for system preference changes
    this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.mediaQuery.addEventListener('change', this.updateTheme.bind(this))
    
    // Listen for stored preference changes
    window.addEventListener('storage', this.updateTheme.bind(this))
  }
  
  disconnect() {
    this.mediaQuery.removeEventListener('change', this.updateTheme.bind(this))
    window.removeEventListener('storage', this.updateTheme.bind(this))
  }
  
  updateTheme() {
    // Check for stored preference
    const storedTheme = localStorage.getItem('theme')
    const wasDark = document.documentElement.classList.contains('dark')
    let isDarkMode = false
    
    if (storedTheme === 'dark') {
      document.documentElement.classList.add('dark')
      isDarkMode = true
      // Update checkbox if present
      if (this.hasDarkModeCheckboxTarget) {
        this.darkModeCheckboxTarget.checked = true
      }
    } else if (storedTheme === 'light') {
      document.documentElement.classList.remove('dark')
      isDarkMode = false
      // Update checkbox if present
      if (this.hasDarkModeCheckboxTarget) {
        this.darkModeCheckboxTarget.checked = false
      }
    } else {
      // Use system preference if no stored preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      if (prefersDark) {
        document.documentElement.classList.add('dark')
        isDarkMode = true
        // Update checkbox if present
        if (this.hasDarkModeCheckboxTarget) {
          this.darkModeCheckboxTarget.checked = true
        }
      } else {
        document.documentElement.classList.remove('dark')
        isDarkMode = false
        // Update checkbox if present
        if (this.hasDarkModeCheckboxTarget) {
          this.darkModeCheckboxTarget.checked = false
        }
      }
    }
    
    // Update theme-color meta tag for PWA
    this.updateThemeColorMetaTag(isDarkMode)
    
    const isDark = document.documentElement.classList.contains('dark')
    if (wasDark !== isDark) {
      // Dispatch event when theme changes so charts and other components can update
      window.dispatchEvent(new CustomEvent('themeChanged', { 
        detail: { isDarkMode: isDark }
      }))
    }
  }
  
  updateThemeColorMetaTag(isDarkMode) {
    // Update the theme-color meta tag for PWA
    let metaThemeColor = document.querySelector('meta[name="theme-color"]')
    if (!metaThemeColor) {
      metaThemeColor = document.createElement('meta')
      metaThemeColor.name = 'theme-color'
      document.head.appendChild(metaThemeColor)
    }
    metaThemeColor.content = isDarkMode ? 'black' : 'white'
  }
  
  toggleTheme() {
    const wasDark = document.documentElement.classList.contains('dark')
    
    if (wasDark) {
      localStorage.setItem('theme', 'light')
      document.documentElement.classList.remove('dark')
      this.updateThemeColorMetaTag(false)
    } else {
      localStorage.setItem('theme', 'dark')
      document.documentElement.classList.add('dark')
      this.updateThemeColorMetaTag(true)
    }
    
    // Dispatch event when theme changes so charts and other components can update
    window.dispatchEvent(new CustomEvent('themeChanged', { 
      detail: { isDarkMode: !wasDark }
    }))
  }

  toggleAndSavePreference(event) {
    const isDark = event.target.checked
    
    if (isDark) {
      localStorage.setItem('theme', 'dark')
      document.documentElement.classList.add('dark')
      this.updateThemeColorMetaTag(true)
    } else {
      localStorage.setItem('theme', 'light')
      document.documentElement.classList.remove('dark')
      this.updateThemeColorMetaTag(false)
    }
    
    // Dispatch event when theme changes so charts and other components can update
    window.dispatchEvent(new CustomEvent('themeChanged', { 
      detail: { isDarkMode: isDark }
    }))
    
    // Leave the form submission to handle saving the preference to the user profile
  }
}