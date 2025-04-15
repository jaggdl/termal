import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modeSelector"];

  connect() {
    this.loadThemePreference();
    this.setupSystemPreferenceListener();

    document.addEventListener("turbo:load", () => {
      this.loadThemePreference();
    });
  }

  loadThemePreference() {
    const storedPreference =
      localStorage.getItem("themePreference") || "system";

    if (this.modeSelectorTarget) {
      this.modeSelectorTarget.value = storedPreference;
    }

    this.applyTheme(storedPreference);
  }

  setupSystemPreferenceListener() {
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", () => {
        const storedPreference =
          localStorage.getItem("themePreference") || "system";
        if (storedPreference === "system") {
          this.applyTheme("system");
        }
      });
  }

  calculateCurrentMode(preference) {
    if (preference === "dark") return true;
    if (preference === "light") return false;
    // If system, use system preference
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  applyTheme(preference) {
    const isDark = this.calculateCurrentMode(preference);

    // Set or remove the dark class on html element
    if (isDark) {
      document.documentElement.classList.add("dark");
      document
        .querySelector('meta[name="theme-color"]')
        .setAttribute("content", "black");
    } else {
      document.documentElement.classList.remove("dark");
      document
        .querySelector('meta[name="theme-color"]')
        .setAttribute("content", "white");
    }
  }

  toggleAndSavePreference(event) {
    // This will be called when the checkbox is toggled
    const isDark = event.target.checked;
    const preference = isDark ? "dark" : "light";

    localStorage.setItem("themePreference", preference);
    this.applyTheme(preference);

    if (this.hasModeSelector) {
      this.modeSelectorTarget.value = preference;
    }
  }

  changeMode(event) {
    // This will be called when the select is changed
    const preference = event.target.value;

    localStorage.setItem("themePreference", preference);
    this.applyTheme(preference);

    if (this.hasDarkModeCheckbox) {
      const isDark = this.calculateCurrentMode(preference);
      this.darkModeCheckboxTarget.checked = isDark;
    }
  }
}
