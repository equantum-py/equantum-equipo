import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "eQ Equipo",
  description: "Portal privado de eQuantum",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
