import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "counter", "slide"]

  connect() {
    this.currentIndex = 0
    this.totalImages = this.slideTargets.length
  }

  open(event) {
    const index = parseInt(event.currentTarget.dataset.imageIndex || 0)
    this.currentIndex = index
    this.showImage(index)
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  next() {
    if (this.currentIndex < this.totalImages - 1) {
      this.currentIndex++
      this.showImage(this.currentIndex)
    }
  }

  previous() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.showImage(this.currentIndex)
    }
  }

  showImage(index) {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("hidden", i !== index)
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${index + 1} / ${this.totalImages}`
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    } else if (event.key === "ArrowRight") {
      this.next()
    } else if (event.key === "ArrowLeft") {
      this.previous()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
}
