import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "meter", "label", "segment"];
  static values = {
    tooShortLabel: String,
    weakLabel: String,
    fairLabel: String,
    strongLabel: String,
  };

  update() {
    const password = this.inputTarget.value;
    const strength = this.#calculateStrength(password);

    if (strength === 0) {
      this.meterTarget.classList.add("hidden");
      return;
    }

    this.meterTarget.classList.remove("hidden");

    const [label, colorClass] = this.#strengthConfig(strength);
    this.labelTarget.textContent = label;
    this.labelTarget.className = `text-xs font-medium mt-1 ${colorClass}`;

    this.segmentTargets.forEach((segment, index) => {
      const filled = index < strength;
      // Reset classes
      segment.className =
        "h-1 flex-1 rounded-full transition-colors duration-200";
      // Add fill color or empty color
      if (filled) {
        segment.classList.add(this.#fillClass(strength));
      } else {
        segment.classList.add("bg-neutral-200", "dark:bg-neutral-700");
      }
    });
  }

  #calculateStrength(password) {
    if (password.length === 0) return 0;
    if (password.length < 10) return 1;

    const classes = this.#countCharClasses(password);

    if (password.length >= 16 && classes >= 2) return 4;
    if (password.length >= 12 || classes >= 3) return 3;
    return 2;
  }

  #countCharClasses(password) {
    let count = 0;
    if (/[a-z]/.test(password)) count++;
    if (/[A-Z]/.test(password)) count++;
    if (/[0-9]/.test(password)) count++;
    if (/[^a-zA-Z0-9]/.test(password)) count++;
    return count;
  }

  #strengthConfig(strength) {
    switch (strength) {
      case 1:
        return [this.tooShortLabelValue, "text-red-600 dark:text-red-400"];
      case 2:
        return [this.weakLabelValue, "text-orange-600 dark:text-orange-400"];
      case 3:
        return [this.fairLabelValue, "text-yellow-600 dark:text-yellow-400"];
      case 4:
        return [this.strongLabelValue, "text-green-600 dark:text-green-400"];
      default:
        return ["", ""];
    }
  }

  #fillClass(strength) {
    switch (strength) {
      case 1:
        return "bg-red-500";
      case 2:
        return "bg-orange-500";
      case 3:
        return "bg-yellow-500";
      case 4:
        return "bg-green-500";
      default:
        return "bg-neutral-200";
    }
  }
}
