import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator", "prevButton", "nextButton", "counter"]

  connect() {
    this.currentIndex = 0
    this.totalSlides = this.slideTargets.length
    
    if (this.totalSlides <= 1) {
      this.hideControls()
      return
    }
    
    this.showSlide(0)
    this.updateCounter()
    this.setupTouchEvents()
  }

  next() {
    if (this.currentIndex < this.totalSlides - 1) {
      this.currentIndex++
      this.showSlide(this.currentIndex)
      this.updateCounter()
    }
  }

  previous() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.showSlide(this.currentIndex)
      this.updateCounter()
    }
  }

  goToSlide(event) {
    const index = parseInt(event.target.dataset.index)
    this.currentIndex = index
    this.showSlide(index)
    this.updateCounter()
  }

  showSlide(index) {
    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("hidden", i !== index)
    })

    // Update indicators
    this.indicatorTargets.forEach((indicator, i) => {
      if (i === index) {
        indicator.classList.remove("bg-white/50")
        indicator.classList.add("bg-white")
      } else {
        indicator.classList.remove("bg-white")
        indicator.classList.add("bg-white/50")
      }
    })

    // Update navigation buttons
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = index === 0
      if (index === 0) {
        this.prevButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      } else {
        this.prevButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      }
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = index === this.totalSlides - 1
      if (index === this.totalSlides - 1) {
        this.nextButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      } else {
        this.nextButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      }
    }
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.totalSlides}`
    }
  }

  hideControls() {
    if (this.hasPrevButtonTarget) this.prevButtonTarget.classList.add("hidden")
    if (this.hasNextButtonTarget) this.nextButtonTarget.classList.add("hidden")
    this.indicatorTargets.forEach(indicator => indicator.classList.add("hidden"))
    if (this.hasCounterTarget) this.counterTarget.classList.add("hidden")
  }

  setupTouchEvents() {
    let startX = 0
    let startY = 0
    let endX = 0
    let endY = 0
    
    this.element.addEventListener("touchstart", (e) => {
      startX = e.touches[0].clientX
      startY = e.touches[0].clientY
    })
    
    this.element.addEventListener("touchend", (e) => {
      endX = e.changedTouches[0].clientX
      endY = e.changedTouches[0].clientY
      this.handleSwipe(startX, startY, endX, endY)
    })
  }

  handleSwipe(startX, startY, endX, endY) {
    const deltaX = endX - startX
    const deltaY = endY - startY
    const minSwipeDistance = 50

    // Check if horizontal swipe is greater than vertical swipe
    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      if (Math.abs(deltaX) > minSwipeDistance) {
        if (deltaX > 0) {
          // Swipe right - go to previous
          this.previous()
        } else {
          // Swipe left - go to next
          this.next()
        }
      }
    }
  }
}