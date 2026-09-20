/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        arabic: ['"Tajawal"', '"Cairo"', '"Amiri"', 'system-ui', 'sans-serif'],
        quran: ['"Amiri Quran"', '"Amiri"', 'serif'],
      },
      colors: {
        emerald: { 50: '#ecfdf5' },
        gold: {
          100: '#fdf6e3',
          200: '#f9e7b2',
          300: '#f5d67b',
          400: '#eab308',
          500: '#c9a227',
          600: '#a8821c',
        },
      },
      boxShadow: { soft: '0 8px 30px rgba(0,0,0,.08)' },
    },
  },
  plugins: [],
}
