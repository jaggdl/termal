// app/javascript/controllers/image_preview_controller.js
import { Controller } from "@hotwired/stimulus";
import heic2any from "heic2any";

export default class extends Controller {
  static targets = ["input", "preview", "previewImage"];

  async previewImage(event) {
    const file = event.target.files[0];

    if (file) {
      let imageFile = file;

      // Check if the file is a HEIC image
      if (
        file.type === "image/heic" ||
        file.name.toLowerCase().endsWith(".heic")
      ) {
        try {
          // Convert HEIC to JPEG using heic2any
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

      reader.onload = (e) => {
        // Update the image source
        this.previewImageTarget.src = e.target.result;

        // Show the preview container
        this.previewTarget.classList.remove("hidden");
      };

      reader.readAsDataURL(imageFile);
    } else {
      // Hide the preview container if no file is selected
      this.previewTarget.classList.add("hidden");
    }
  }
}
