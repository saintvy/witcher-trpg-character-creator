import { MetadataRoute } from "next";
import { getAbsoluteUrl } from "./seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/api/", "/builder/", "/characters/", "/settings/", "/sheet/", "/survey-graph.html"],
      },
    ],
    sitemap: getAbsoluteUrl("/sitemap.xml"),
    host: getAbsoluteUrl("/").replace(/\/$/, ""),
  };
}
