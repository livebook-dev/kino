import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { createPlaceholder } from "./Placeholder";

function renderApp(ctx, data) {
  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} data={data} />);
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

  // Force font loading with invisible element
  const fontPreloader = document.createElement("div");
  fontPreloader.setAttribute("aria-hidden", "true");
  fontPreloader.style.cssText = `
    position: absolute;
    visibility: hidden;
    pointer-events: none;
    left: -9999px;
  `;
  fontPreloader.innerHTML =
    "<span style=\"font-family:'JetBrains Mono'\">Font preload</span>" +
    "<span style=\"font-family:'Inter'\">Font preload</span>";
  document.body.appendChild(fontPreloader);

  await Promise.all(cssPromises);

  const FONT_TIMEOUT = 500;

  try {
    if (document.fonts && document.fonts.ready) {
      // Use Font Loading API with timeout fallback
      await Promise.race([
        document.fonts.ready,
        new Promise((resolve) => setTimeout(resolve, FONT_TIMEOUT)),
      ]);
    } else {
      // Simple timeout fallback for older browsers
      await new Promise((resolve) => setTimeout(resolve, FONT_TIMEOUT));
    }
  } finally {
    // Clean up font loading elements
    document.body.removeChild(fontPreloader);
  }
}

export async function init(ctx, data) {
  const placeholder = createPlaceholder();
  ctx.root.appendChild(placeholder);

  try {
    await loadStyles(ctx);
  } catch (error) {
    console.error("Error loading styles:", error);
  } finally {
    // Remove placeholder and render the app regardless of errors
    if (placeholder.parentNode) {
      ctx.root.removeChild(placeholder);
    }
    renderApp(ctx, data);
  }
}
