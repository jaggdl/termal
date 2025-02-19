// app/javascript/controllers/timezone_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.populateTimezones()
    this.setCurrentTimezone()
  }

  populateTimezones() {
    // Get all available timezone names
    const timezones = Intl.supportedValuesOf('timeZone')

    // Create array with timezone info including offset
    const timezoneData = timezones.map(timezone => {
      const formatter = new Intl.DateTimeFormat('en', {
        timeZone: timezone,
        timeZoneName: 'short'
      })

      // Get current offset
      const now = new Date()
      const offsetString = formatter.formatToParts(now).find(part =>
        part.type === 'timeZoneName'
      ).value

      // Convert offset to minutes for sorting
      const offsetMatch = offsetString.match(/GMT([+-])(\d{1,2}):?(\d{2})?/)
      let offsetMinutes = 0
      if (offsetMatch) {
        const [, sign, hours, minutes] = offsetMatch
        offsetMinutes = (parseInt(hours) * 60 + (parseInt(minutes) || 0)) * (sign === '+' ? 1 : -1)
      }

      return {
        name: timezone,
        offsetString: offsetString,
        offsetMinutes: offsetMinutes
      }
    })

    // Sort by offset
    timezoneData.sort((a, b) => a.offsetMinutes - b.offsetMinutes)

    // Create and append options
    timezoneData.forEach(({ name, offsetString }) => {
      const option = document.createElement('option')
      option.value = name
      option.text = `${name} (${offsetString})`
      this.selectTarget.appendChild(option)
    })
  }

  setCurrentTimezone() {
    const currentTimezone = this.selectTarget.dataset.selected || ''
    if (currentTimezone) {
      this.selectTarget.value = currentTimezone
    }
  }
}
