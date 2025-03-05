import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { createTableSkeleton } from "./Skeleton";

export async function init(ctx, data) {
  ctx.root.appendChild(createTableSkeleton());

  try {
    await loadStyles(ctx);
  } finally {
    const root = createRoot(ctx.root);
    root.render(<App ctx={ctx} data={data} />);
  }
}

async function loadStyles(ctx) {
  const cssPromises = [
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap",
    ),
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap",
    ),
    ctx.importCSS("main.css"),
  ];

  // We force all fonts to be loaded by adding an invisible element,
  // and then we explicitly wait for the fonts to finish loading.
  // This is important on first uncached render. If we don't wait
  // and render the table with fallback fonts, the columns get wrong
  // default widths. Also, on Firefox ans Safari, once the font is
  // loaded, the table only updates on hover, which is bad UX.

  const fontPreloader = document.createElement("div");
  fontPreloader.setAttribute("aria-hidden", "true");
  fontPreloader.style.cssText = `
    position: absolute;
    visibility: hidden;
    left: -9999px;
  `;
  fontPreloader.innerHTML = `
    <span style="font-family: 'JetBrains Mono'">
      <span style="font-weight: 400">preload</span>"
      <span style="font-weight: 500">preload</span>"
      <span style="font-weight: 600">preload</span>"
    </span>"
    <span style="font-family: 'Inter'">
      <span style="font-weight: 400">preload</span>"
      <span style="font-weight: 500">preload</span>"
      <span style="font-weight: 600">preload</span>"
    </span>"
  `;

  document.body.appendChild(fontPreloader);

  try {
    await Promise.all(cssPromises);

    if (document.fonts && document.fonts.ready) {
      await document.fonts.ready;
    }
  } finally {
    document.body.removeChild(fontPreloader);
  }
}
