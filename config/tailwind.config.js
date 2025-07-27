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
      screens: {
        'sm': '480px' // Below this is a phone in portrait mode
      },
      fontFamily: {
        sans: ['"Titillium Web"', ...defaultTheme.fontFamily.sans],
        mono: ['"Fira Code"', ...defaultTheme.fontFamily.mono],
      },
      fontSize: {
        lg:   ['1.4375rem', '2.156rem'], // Base/01 23px, 34.5px
        base: ['1.1875rem', '1.781rem'], // Base/02 19px, 28.5px
        sm:   ['1.0000rem', '1.500rem'], // Base/03 16px, 24px
        xs:   ['0.8750rem', '1.313rem'], // Base/04 14px, 21px

        d1: ['3.1875rem', '3.825rem'], // Display/01 51px, 61.2px
        d2: ['2.9375rem', '3.525rem'], // Display/02 47px, 56.4px
        d3: ['2.6875rem', '3.225rem'], // Display/03 43px, 51.6px
        h1: ['2.4375rem', '2.925rem'], // Header/01 39px, 46.8px
        h2: ['2.1875rem', '2.625rem'], // Header/02 35px, 42px
        h3: ['1.8750rem', '2.325rem'], // Header/03 31px, 37.2px
        h4: ['1.6875rem', '2.025rem'], // Header/04 27px, 32.4px
        b1: ['1.4375rem', '2.156rem'], // Base/01 23px, 34.5px
        b2: ['1.1875rem', '1.781rem'], // Base/02 19px, 28.5px
        b3: ['1.0000rem', '1.500rem'], // Base/03 16px, 24px
        b4: ['0.8750rem', '1.313rem'], // Base/04 14px, 21px
        c1: ['1.6875rem', '2.025rem'], // Code/01 27px, 32.4px
        c2: ['1.4375rem', '1.725rem'], // Code/02 23px, 27.6px
        c3: ['1.1250rem', '1.350rem'], // Code/03 18px, 21.6px
        c4: ['1.0000rem', '1.200rem'], // Code/04 16px, 19.2px
      },
      colors: {
        transparent: 'transparent',
        current: 'currentColor',
        'white': '#FFFFFF',
        'black': '#000000',
        'red': { // Warn / Failure
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
        'orange': { // Primary
          '050': '#FFF8F1',
          100: '#FFF0EC',
          200: '#FFC6AD',
          300: '#FFA983',
          400: '#FF7539',
          500: '#F74C27',
          DEFAULT: '#F74C27', // 500 brand primary
          600: '#E04300',
          700: '#AD2F14',
          800: '#761A05',
          900: '#581A0C',
          950: '#3A1007',
        },
        'yellow': { // Alert
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
        'green': { // Success
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
        'blue': { // Info
          100: '#F3F9FF',
          200: '#E1F1FF',
          300: '#92C0F4',
          400: '#76ADEC',
          500: '#6999D2',
          600: '#5B86B8',
          700: '#3F699A',
          800: '#234C7D',
          900: '#113765',
          950: '#06264C',
        },
        'neutral': {
          // WHITE
          // Light
          //   background (general)
          //   secondary search bar background
          // Dark
          //   primary text
          //   primary icons
          '000': '#FFFFFF',

          // neutral-050
          // Light
          //   work canvas
          //   form input
          // Dark (not used)
          '050': '#FBFBFB',

          // neutral-100
          // Light
          //   primary search bar bg
          // Dark (not used)
          '100': '#EEF1F3',

          // neutral-200
          // Light
          //   tab hover
          //   pagination hover
          //   neutral toasts
          //   neutral badges
          //   neutral labels (dropdown)
          //   low performance indicators
          // Dark
          //   primary text hover
          '200': '#E3E7EA',

          // neutral-300
          // Light
          //   disabled buttons
          //   disabled form input
          //   list dividing line
          //   tab dividing line
          //   outside line default
          //     search bar
          //     dropdown
          //     chips
          // Dark (not used)
          '300': '#D7DEE3',

          // neutral-400
          // Light (not used)
          // Dark
          //   secondary text
          //     disabled button text
          //     inactive search bar
          //     nav breadcrumbs
          //   secondary icons
          '400': '#C6CED5',

          // neutral-500
          // Light
          //   outside stroke
          //     general containers
          //     neutral toasts
          //   outside stroke active states
          //     search bar
          //     drop downs
          //     chips
          // Dark (not used)
          '500': '#AEB8C1',

          // neutral-600
          // Light
          //   secondary text
          //     disabled button text
          //     inactive search bar
          //     nav breadcrumbs
          //     search result gem description captions
          //     text counters [  Gems  4  ]
          //     sort by - not active
          //   secondary icons
          // Dark
          //   secondary text
          //     search result gem description captions
          //     text counters [  Gems  4  ]
          //     sort by - not active
          //
          '600': '#6C7583',

          // neutral-700
          // Light (not used)
          // Dark
          //   disabled buttons
          //   disabled form input
          //   list dividing line
          //   tab dividing line
          //   outside line default
          //     search bar
          //     dropdown
          //     chips
          //   outside stroke
          //     general containers
          //     neutral toasts
          //   outside stroke active states
          //     search bar
          //     drop downs
          //     chips
          '700': '#434B59',

          // neutral-800
          // Light
          //   primary text
          //   primary icons
          // Dark
          //   tab hover
          //   pagination hover
          //   neutral toasts
          //   neutral badges
          //   neutral labels (dropdown)
          //   low performance indicators
          '800': '#333A45',

          // neutral-900
          // Light (not used)
          // Dark
          //   primary search bar background
          '900': '#222831',

          // neutral-950
          // Light (not used)
          // Dark
          //   work canvas
          //   form input
          '950': '#16191E',

          // BLACK
          // Light
          //   primary text hover
          // Dark
          //   background (general)
          //   secondary search bar background
          '1000': '#000000',
        },
      },
    },
  },
  plugins: [
  ],
  corePlugins: {
  },
};
