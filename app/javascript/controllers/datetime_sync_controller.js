import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["localInput", "utcInput"]

  connect() {
    this.syncToUTC()
    this.timezone = this.element.dataset.datetimeSyncTimezone || Intl.DateTimeFormat().resolvedOptions().timeZone
  }

  syncToUTC() {
    const localValue = this.localInputTarget.value
    if (!localValue) return

    const localDate = new Date(localValue)
    const utcDate = new Date(localDate.toLocaleString("en-US", { timeZone: this.timezone }))
    const utcString = utcDate.toISOString().slice(0, 16)

    this.utcInputTarget.value = utcString
  }

  localChanged() {
    this.syncToUTC()
  }
}
