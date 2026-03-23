import type { Metadata } from "next";
import { ClientLayout } from "./client-layout";
import { getAbsoluteUrl, getSiteUrl } from "./seo";
import "./globals.css";
import "./ddlist.css";

const siteName = "Witcher Character Creator";
const siteTitle = "Witcher Character Creator | Witcher TTRPG Generator";
const siteDescription =
  "Create, manage, and print characters for the Witcher Tabletop Roleplaying Game with a free unofficial generator.";
const googleSiteVerification = process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION?.trim();

export const metadata: Metadata = {
  metadataBase: new URL(getSiteUrl()),
  title: {
    default: siteTitle,
    template: `%s | ${siteName}`,
  },
  icons: {
    icon: [
      {
        url: "/logo.png",
        type: "image/png",
        sizes: "128x128",
      },
    ],
    shortcut: ["/logo.png"],
    apple: [
      {
        url: "/logo.png",
        sizes: "128x128",
        type: "image/png",
      },
    ],
  },
  applicationName: siteName,
  description: siteDescription,
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
  alternates: {
    canonical: "/",
  },
  category: "games",
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  verification: googleSiteVerification
    ? {
        google: googleSiteVerification,
      }
    : undefined,
  openGraph: {
    title: siteTitle,
    description: siteDescription,
    url: getAbsoluteUrl("/"),
    siteName,
    type: "website",
    locale: "en_US",
    images: [
      {
        url: getAbsoluteUrl("/og-card.jpg"),
        width: 1424,
        height: 752,
        alt: `${siteName} preview card`,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: siteTitle,
    description: siteDescription,
    images: [getAbsoluteUrl("/og-card.jpg")],
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
