const defaultTheme = require("tailwindcss/defaultTheme");

/** @type {import('tailwindcss').Config} */
module.exports = {
  mode: "jit",
  prefix: "tw-", // While we still have non-tailwind classes
  content: [
    "./app/views/**/*.rb",
    "./app/components/**/*rb",
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim,rb}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: [
          "Helvetica Neue",
          "Helvetica",
          "Arial",
          ...defaultTheme.fontFamily.sans,
        ],
      },
      colors: {
        "rubygems-red": "#e74c3c",
        blackish: "#141c22",
        grayish: "#c1c4ca",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
  corePlugins: {
    preflight: false,
  },
};
