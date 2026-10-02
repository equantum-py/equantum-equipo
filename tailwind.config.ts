import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: "#08245c",
          dark: "#06183d",
          cyan: "#20b8e6",
          soft: "#f4f7fb",
        },
      },
      boxShadow: {
        soft: "0 14px 40px rgba(8,36,92,.08)",
      },
    },
  },
  plugins: [],
};

export default config;
