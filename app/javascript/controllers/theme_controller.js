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
    
    if (storedTheme === 'dark') {
      document.documentElement.classList.add('dark')
      // Update checkbox if present
      if (this.hasDarkModeCheckboxTarget) {
        this.darkModeCheckboxTarget.checked = true
      }
    } else if (storedTheme === 'light') {
      document.documentElement.classList.remove('dark')
      // Update checkbox if present
      if (this.hasDarkModeCheckboxTarget) {
        this.darkModeCheckboxTarget.checked = false
      }
    } else {
      // Use system preference if no stored preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      if (prefersDark) {
        document.documentElement.classList.add('dark')
        // Update checkbox if present
        if (this.hasDarkModeCheckboxTarget) {
          this.darkModeCheckboxTarget.checked = true
        }
      } else {
        document.documentElement.classList.remove('dark')
        // Update checkbox if present
        if (this.hasDarkModeCheckboxTarget) {
          this.darkModeCheckboxTarget.checked = false
        }
      }
    }
    
    const isDark = document.documentElement.classList.contains('dark')
    if (wasDark !== isDark) {
      // Dispatch event when theme changes so charts and other components can update
      window.dispatchEvent(new CustomEvent('themeChanged', { 
        detail: { isDarkMode: isDark }
      }))
    }
  }
  
  toggleTheme() {
    const wasDark = document.documentElement.classList.contains('dark')
    
    if (wasDark) {
      localStorage.setItem('theme', 'light')
      document.documentElement.classList.remove('dark')
    } else {
      localStorage.setItem('theme', 'dark')
      document.documentElement.classList.add('dark')
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
    } else {
      localStorage.setItem('theme', 'light')
      document.documentElement.classList.remove('dark')
    }
    
    // Dispatch event when theme changes so charts and other components can update
    window.dispatchEvent(new CustomEvent('themeChanged', { 
      detail: { isDarkMode: isDark }
    }))
    
    // Leave the form submission to handle saving the preference to the user profile
  }
}