import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Characters",
  robots: {
    index: false,
    follow: false,
    googleBot: {
      index: false,
      follow: false,
    },
  },
};

export default function CharactersLayout({ children }: { children: React.ReactNode }) {
  return children;
}

