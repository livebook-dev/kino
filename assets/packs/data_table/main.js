import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { createTableSkeleton } from "./Skeleton";

export async function init(ctx, data) {
  ctx.root.appendChild(createTableSkeleton());

  await Promise.all([
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap",
    ),
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap",
    ),
    ctx.importCSS("main.css"),
  ]);

  // We force all fonts to be loaded before rendering the table.
  // This is important on first uncached render. If we don't wait
  // and render the table with fallback fonts, the columns get wrong
  // default widths. Also, in Firefox ans Safari, once the font is
  // loaded, the table only updates on hover, which is bad UX. That
  // said, in Firefox, this doesn't help 100% of the time either.
  await Promise.race([
    Promise.all([
      document.fonts.load("400 16px 'JetBrains Mono'"),
      document.fonts.load("500 16px 'JetBrains Mono'"),
      document.fonts.load("600 16px 'JetBrains Mono'"),
      document.fonts.load("400 16px Inter"),
      document.fonts.load("500 16px Inter"),
      document.fonts.load("600 16px Inter"),
    ]),
    // If a font request fails, the promises may not be resolved, so
    // we add a timeout just to make sure this finishes at some point.
    new Promise((resolve) => setTimeout(resolve, 5000)),
  ]);

  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} data={data} />);
}
