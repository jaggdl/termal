import { Controller } from "@hotwired/stimulus";
import heic2any from "heic2any";

export default class extends Controller {
  static targets = ["input", "previewCanvas", "previewContainer"];

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
    const files = Array.from(event.target.files);
    
    this.clearAllPreviews();

    if (files.length === 0) {
      return;
    }

    for (let i = 0; i < files.length; i++) {
      await this.createPreviewForFile(files[i], i);
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

    const canvas = document.createElement("canvas");
    canvas.width = 1000;
    canvas.height = 1000;
    canvas.className = "w-48 h-48 object-cover rounded-lg shadow-sm bg-gray-100 dark:bg-gray-800";
    
    const ctx = canvas.getContext("2d");
    
    this.previewContainerTarget.appendChild(canvas);

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
        canvas.remove();
      };

      img.src = e.target.result;
    };

    reader.readAsDataURL(imageFile);
  }

  clearAllPreviews() {
    const canvases = this.previewContainerTarget.querySelectorAll("canvas:not([data-image-preview-target='previewCanvas'])");
    canvases.forEach(canvas => canvas.remove());
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
