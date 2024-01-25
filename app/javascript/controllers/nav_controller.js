import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropdownButton", // carrot icon in full size
    "dropdown", // full size dropdown
    "sandwichIcon", // mobile sandwich icon
    "header", 
    "main",
    "footer",
    "headerSearch",
    "headerLogo"
  ]

  static mobileNavExpandedClass = 'mobile-nav-is-expanded';

  connect() {
    // variable to support mobile nav tab behaviour
    // * skipSandwichIcon is for skipping sandwich icon
    //   when you tab from "gem" icon
    // * tabDirection is for hiding and showing navbar
    //   when you tab in and out
    this.skipSandwichIcon = true;

    document.addEventListener("click", (e) => {
      // Must check both dropdowns otherwise you always close
      // the dropdown because one or the other isn't being clicked
      if (!this.dropdownTarget.contains(e.target) && !this.headerTarget.contains(e.target)) {
        this.dropdownTarget.classList.remove('is-expanded');
        this.collapseMobileNav();
      }
    });
  }

  dropdownButtonTargetConnected(el) {
    el.addEventListener("click", (e) => {
      e.preventDefault();
      this.dropdownTarget.classList.toggle('is-expanded');
    });
  }

  sandwichIconTargetConnected(el) {
    el.addEventListener("click", (e) => {
      e.preventDefault();

      if (this.headerTarget.classList.contains(this.constructor.mobileNavExpandedClass)) {
        this.collapseMobileNav();
      } else {
        this.expandMobileNav();
      }
    });

    el.addEventListener('focusin', () => {
      if (this.skipSandwichIcon) {
        this.expandeMobileNav();
        this.headerSearchTarget.focus();
        this.skipSandwichIcon = false;
      } else {
        this.collapseMobileNav();
        this.headerLogoTarget.focus();
        this.skipSandwichIcon = true;
      }
    });
  }

  collapseMobileNav() {
    this.headerTarget.classList.remove(this.constructor.mobileNavExpandedClass);
    this.mainTarget.classList.remove(this.constructor.mobileNavExpandedClass);
    this.footerTarget.classList.remove(this.constructor.mobileNavExpandedClass);
  }

  expandMobileNav() {
    this.headerTarget.classList.add(this.constructor.mobileNavExpandedClass);
    this.mainTarget.classList.add(this.constructor.mobileNavExpandedClass);
    this.footerTarget.classList.add(this.constructor.mobileNavExpandedClass);
  }
}