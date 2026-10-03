import type { Metadata } from "next";
import "./globals.css";
import EQAssistant from "./components/EQAssistant";

export const metadata: Metadata = {
  title: "eQ Equipo",
  description: "Portal privado de eQuantum",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body>{children}<EQAssistant /></body>
    </html>
  );
}
