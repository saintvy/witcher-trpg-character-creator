import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Character Builder",
  robots: {
    index: false,
    follow: false,
    googleBot: {
      index: false,
      follow: false,
    },
  },
};

export default function BuilderLayout({ children }: { children: React.ReactNode }) {
  return children;
}

