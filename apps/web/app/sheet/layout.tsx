import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Character Sheet Prototype",
  robots: {
    index: false,
    follow: false,
    googleBot: {
      index: false,
      follow: false,
    },
  },
};

export default function SheetLayout({ children }: { children: React.ReactNode }) {
  return children;
}
