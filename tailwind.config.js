/** @type {import('tailwindcss').Config} */
export default {
  content: ["./priv/**/*.html", "./src/**/*.gleam"],
  theme: {
    extend: {
      colors: {
        primary: "#123456",
      },
    },
  },
  plugins: [],
};
