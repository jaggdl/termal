import { Controller } from "@hotwired/stimulus";
import heic2any from "heic2any";

export default class extends Controller {
  static targets = ["input", "previewCanvas", "imageUrlInput"];

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
          quality: 0.8, // Adjust quality as needed
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

        const base64Image = this.previewCanvasTarget.toDataURL(
          "image/jpeg",
          0.8,
        );
        this.imageUrlInputTarget.value = base64Image;
      };
      img.onerror = () => {
        console.error("Failed to load image");
        this.clearCanvas(ctx);
      };

      img.src = e.target.result;
    };

    reader.readAsDataURL(imageFile);
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
