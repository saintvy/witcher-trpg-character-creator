import type { MetadataRoute } from "next";
import { getAbsoluteUrl } from "./seo";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Witcher Character Creator",
    short_name: "WCC",
    description:
      "Free unofficial character creator and generator for the Witcher Tabletop Roleplaying Game.",
    start_url: "/",
    display: "standalone",
    background_color: "#14110f",
    theme_color: "#c67a2b",
    icons: [
      {
        src: getAbsoluteUrl("/logo.png"),
        sizes: "128x128",
        type: "image/png",
      },
    ],
  };
}
