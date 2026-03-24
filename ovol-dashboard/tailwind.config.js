/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        kheteebaadi: {
          primary: '#2E7D32',
          'primary-dark': '#1B5E20',
          'primary-light': '#81C784',
          accent: '#EF6C00',
          success: '#43A047',
          warning: '#FFA726',
          error: '#E53935',
        },
      },
      fontFamily: {
        sans: ['system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
