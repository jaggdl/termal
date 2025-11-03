import { Controller } from "@hotwired/stimulus";
import heic2any from "heic2any";

export default class extends Controller {
  static targets = ["input", "previewCanvas", "previewContainer"];

  connect() {
    this.files = [];
  }

  triggerFileInput() {
    this.inputTarget.click();
  }

  async previewImage(event) {
    const file = event.target.files[0];
    const ctx = this.previewCanvasTarget.getContext("2d");

    this.clearCanvas(ctx);

    if (!file) {
      return;
    }

    let imageFile = file;

    if (
      file.type === "image/heic" ||
      file.name.toLowerCase().endsWith(".heic")
    ) {
      try {
        imageFile = await heic2any({
          blob: file,
          toType: "image/jpeg",
          quality: 0.8,
        });
      } catch (error) {
        console.error("Error converting HEIC image:", error);
        alert(
          "Failed to process HEIC image. Please upload a different format.",
        );
        return;
      }
    }

    const reader = new FileReader();

    reader.onload = async (e) => {
      const img = new Image();

      img.onload = () => {
        const scale = Math.min(1000 / img.width, 1000 / img.height);
        const x = (1000 - img.width * scale) / 2;
        const y = (1000 - img.height * scale) / 2;

        ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
      };
      img.onerror = () => {
        console.error("Failed to load image");
        this.clearCanvas(ctx);
      };

      img.src = e.target.result;
    };

    reader.readAsDataURL(imageFile);
  }

  async previewImages(event) {
    const newFiles = Array.from(event.target.files);

    this.files = [...this.files, ...newFiles];

    this.updateFileInput();
    this.renderPreviews();
  }

  async renderPreviews() {
    this.clearAllPreviews();

    if (this.files.length === 0) {
      return;
    }

    for (let i = 0; i < this.files.length; i++) {
      await this.createPreviewForFile(this.files[i], i);
    }
  }

  async createPreviewForFile(file, index) {
    let imageFile = file;

    if (
      file.type === "image/heic" ||
      file.name.toLowerCase().endsWith(".heic")
    ) {
      try {
        imageFile = await heic2any({
          blob: file,
          toType: "image/jpeg",
          quality: 0.8,
        });
      } catch (error) {
        console.error("Error converting HEIC image:", error);
        return;
      }
    }

    const wrapper = document.createElement("div");
    wrapper.className = "relative w-full aspect-square";
    wrapper.dataset.index = index;

    const canvas = document.createElement("canvas");
    canvas.width = 1000;
    canvas.height = 1000;
    canvas.className = "w-full h-full object-cover rounded-lg shadow-sm bg-gray-100 dark:bg-gray-800";

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.className = "absolute -top-2 -right-2 w-6 h-6 bg-red-500 hover:bg-red-600 text-white rounded-full flex items-center justify-center shadow-lg transition-colors";
    removeButton.innerHTML = "×";
    removeButton.dataset.action = "click->image-preview#removeImage";
    removeButton.dataset.index = index;

    wrapper.appendChild(canvas);
    wrapper.appendChild(removeButton);

    const ctx = canvas.getContext("2d");

    this.previewContainerTarget.appendChild(wrapper);

    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        const scale = Math.min(1000 / img.width, 1000 / img.height);
        const x = (1000 - img.width * scale) / 2;
        const y = (1000 - img.height * scale) / 2;

        ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
      };
      img.onerror = () => {
        console.error("Failed to load image");
        wrapper.remove();
      };

      img.src = e.target.result;
    };

    reader.readAsDataURL(imageFile);
  }

  removeImage(event) {
    const index = parseInt(event.currentTarget.dataset.index);
    this.files.splice(index, 1);

    this.updateFileInput();
    this.renderPreviews();
  }

  updateFileInput() {
    const dt = new DataTransfer();
    this.files.forEach(file => dt.items.add(file));
    this.inputTarget.files = dt.files;
  }

  clearAllPreviews() {
    const wrappers = this.previewContainerTarget.querySelectorAll("div[data-index]");
    wrappers.forEach(wrapper => wrapper.remove());
  }

  clearCanvas(ctx) {
    ctx.clearRect(
      0,
      0,
      this.previewCanvasTarget.width,
      this.previewCanvasTarget.height,
    );
  }
}
