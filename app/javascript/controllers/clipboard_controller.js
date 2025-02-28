import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    const input = this.sourceTarget
    input.select()
    document.execCommand('copy')
    
    // Create a tooltip
    const tooltip = document.createElement('div')
    tooltip.textContent = 'Copied!'
    tooltip.style.position = 'fixed'
    tooltip.style.padding = '6px 12px'
    tooltip.style.background = 'rgba(0, 0, 0, 0.8)'
    tooltip.style.color = 'white'
    tooltip.style.borderRadius = '4px'
    tooltip.style.fontSize = '14px'
    tooltip.style.pointerEvents = 'none'
    tooltip.style.zIndex = '1000'
    
    // Position it near the copy button
    const copyButton = event.currentTarget
    const rect = copyButton.getBoundingClientRect()
    tooltip.style.top = `${rect.top - 35}px`
    tooltip.style.left = `${rect.left + rect.width/2 - 30}px`
    
    document.body.appendChild(tooltip)
    
    // Remove after 2 seconds
    setTimeout(() => {
      document.body.removeChild(tooltip)
    }, 2000)
  }
}