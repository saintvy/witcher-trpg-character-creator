import type { Metadata } from "next";
import { ClientLayout } from "./client-layout";
import "./globals.css";
import "./ddlist.css";

export const metadata: Metadata = {
  title: "Witcher Character Creator | Witcher TTRPG Generator",
  description: "Create, manage, and print your characters for the Witcher Tabletop Roleplaying Game (TTRPG). Fast, easy, and free unofficial Witcher Character Generator.",
  keywords: [
    "Witcher",
    "Witcher TTRPG",
    "Witcher Tabletop",
    "Witcher Character Creator",
    "Witcher Character Generator",
    "Ведьмак НРИ",
    "Генератор персонажей Ведьмак"
  ],
  authors: [{ name: "Witcher TRPG Fan Community" }],
  robots: "index, follow",
  openGraph: {
    title: "Witcher Character Creator | Witcher TTRPG Generator",
    description: "Create and manage your characters for the Witcher Tabletop Roleplaying Game. Unofficial free generator.",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "Witcher Character Creator | Witcher TTRPG Generator",
    description: "Create and manage your characters for the Witcher Tabletop Roleplaying Game. Unofficial free generator.",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ClientLayout>{children}</ClientLayout>
      </body>
    </html>
  );
}
