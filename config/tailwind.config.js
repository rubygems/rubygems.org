const defaultTheme = require("tailwindcss/defaultTheme");

/** @type {import('tailwindcss').Config} */
module.exports = {
  mode: "jit",
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
        sans: ['"Titillium Web"', ...defaultTheme.fontFamily.sans],
        mono: ['"Fira Code"', ...defaultTheme.fontFamily.mono],
      },
      fontSize: {
        lg:   ['1.4375rem', '2.156rem'], /* Base/01 23px, 34.5px */
        base: ['1.1875rem', '1.781rem'], /* Base/02 19px, 28.5px */
        sm:   ['1.0000rem', '1.500rem'], /* Base/03 16px, 24px */
        xs:   ['0.8750rem', '1.313rem'], /* Base/04 14px, 21px */

        d1: ['3.1875rem', '3.825rem'], /* Display/01 51px, 61.2px */
        d2: ['2.9375rem', '3.525rem'], /* Display/02 47px, 56.4px */
        d3: ['2.6875rem', '3.225rem'], /* Display/03 43px, 51.6px */
        h1: ['2.4375rem', '2.925rem'], /* Header/01 39px, 46.8px */
        h2: ['2.1875rem', '2.625rem'], /* Header/02 35px, 42px */
        h3: ['1.9375rem', '2.325rem'], /* Header/03 31px, 37.2px */
        h4: ['1.6875rem', '2.025rem'], /* Header/04 27px, 32.4px */
        b1: ['1.4375rem', '2.156rem'], /* Base/01 23px, 34.5px */
        b2: ['1.1875rem', '1.781rem'], /* Base/02 19px, 28.5px */
        b3: ['1.0000rem', '1.500rem'], /* Base/03 16px, 24px */
        b4: ['0.8750rem', '1.313rem'], /* Base/04 14px, 21px */
        c1: ['1.6875rem', '2.025rem'], /* Code/01 27px, 32.4px */
        c2: ['1.4375rem', '1.725rem'], /* Code/02 23px, 27.6px */
        c3: ['1.1250rem', '1.350rem'], /* Code/03 18px, 21.6px */
        c4: ['1.0000rem', '1.200rem'], /* Code/04 16px, 19.2px */
      },
      colors: {
        transparent: 'transparent',
        current: 'currentColor',
        'white': '#ffffff',
        'red': {
          100: '#FFEEF1',
          200: '#FFC4CD',
          300: '#FF9CB0',
          400: '#FF0E3B',
          500: '#E4002B',
          600: '#BA0023',
          700: '#970019',
          800: '#730012',
          900: '#58000A',
        },
        'orange': {
          100: '#FFF0EC',
          200: '#FFD0C5',
          300: '#FFA983',
          400: '#FF7539',
          500: '#F74C27',
          600: '#E54523',
          700: '#AD2F14',
          800: '#761A05',
          900: '#631200',
        },
        'yellow': {
          100: '#FFFBF7',
          200: '#FFF4EA',
          300: '#FFE4BB',
          400: '#FFC772',
          500: '#FFAB2D',
          600: '#D38C22',
          700: '#A66D17',
          800: '#7A4E0C',
          900: '#4D2E00',
        },
        'green': {
          100: '#F1FFFE',
          200: '#E1FFFC',
          300: '#C9FFF9',
          400: '#06B8B9',
          500: '#05A3A7',
          600: '#03858B',
          700: '#006770',
          800: '#004F56',
          900: '#00373B',
        },
        'blue': {
          100: '#F3F9FF',
          200: '#E1F1FF',
          300: '#92C0F4',
          400: '#76ADEC',
          500: '#6999D2',
          600: '#5B86B8',
          700: '#3F699A',
          800: '#234C7D',
          900: '#113765',
        },
        'neutral': {
          '000': '#FFFFFF',
          '050': '#FBFBFB',
          '100': '#F6F6F6',
          '200': '#EEEEEE',
          '300': '#E2E2E2',
          '400': '#D5D5D5',
          '500': '#C3C5C7',
          '600': '#969CA7',
          '700': '#636B79',
          '800': '#454C59',
          '850': '#2F3643',
          '900': '#13181F',
          '950': '#191E26',
        },
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
  },
};
