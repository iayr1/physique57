/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          500: '#4F46E5',
          600: '#4338CA',
          700: '#3730A3',
          800: '#312E81',
          900: '#1E1B4B',
        },
        neo: {
          border: '#0F172A',
          bg: '#FFFDF5',
          yellow: '#FFDE59',
          pink: '#FF66C4',
          cyan: '#00F0FF',
          green: '#00E676',
          purple: '#8C52FF',
          orange: '#FF914D',
          indigo: '#4F46E5',
        },
        slate: {
          850: '#151F32',
          900: '#0F172A',
        }
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'system-ui', 'sans-serif'],
        display: ['Outfit', 'Plus Jakarta Sans', 'sans-serif'],
      },
      boxShadow: {
        'brutal': '4px 4px 0px 0px #0F172A',
        'brutal-lg': '6px 6px 0px 0px #0F172A',
        'brutal-sm': '2px 2px 0px 0px #0F172A',
        'brutal-white': '4px 4px 0px 0px #FFFFFF',
        'soft': '0 4px 20px -2px rgba(15, 23, 42, 0.05)',
      },
      borderWidth: {
        '3': '3px',
      },
      animation: {
        'pulse-subtle': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'fade-in': 'fadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(6px) scale(0.98)' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        }
      }
    },
  },
  plugins: [],
}
