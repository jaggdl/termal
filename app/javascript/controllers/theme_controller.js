import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
    } else if (storedTheme === 'light') {
      document.documentElement.classList.remove('dark')
    } else {
      // Use system preference if no stored preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      if (prefersDark) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
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
}