import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";

function createLoadingPlaceholder() {
  const placeholderHTML = `
    <div class="font-loading-placeholder">
      <div class="shimmer-container">
        <div class="shimmer-table-container">
          <table class="shimmer-table">
            <thead>
              <tr>
                <th><div class="shimmer header-shimmer w-12"></div></th>
                <th><div class="shimmer header-shimmer w-32"></div></th>
                <th><div class="shimmer header-shimmer w-48"></div></th>
                <th><div class="shimmer header-shimmer w-24"></div></th>
                <th><div class="shimmer header-shimmer w-20"></div></th>
              </tr>
            </thead>
            <tbody>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
              <tr><td><div class="shimmer w-12"></div></td><td><div class="shimmer w-32"></div></td><td><div class="shimmer w-48"></div></td><td><div class="shimmer w-24"></div></td><td><div class="shimmer w-20"></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `;

  const container = document.createElement("div");
  container.innerHTML = placeholderHTML.trim();
  return container.firstChild;
}

/**
 * Checks if the required fonts are already loaded
 * @returns {boolean} True if fonts are loaded, false otherwise
 */
function areFontsLoaded() {
  return (
    document.fonts &&
    Array.from(document.fonts).some(
      (font) => font.family.includes("JetBrains Mono") && font.loaded,
    )
  );
}

/**
 * Renders the app with required font styles
 */
function renderApp(ctx, data) {
  const root = createRoot(ctx.root);
  root.render(
    <>
      <style>
        {`
          .gdg-cell, .gdg-header {
            font-family: 'JetBrains Mono', monospace !important;
            -webkit-font-smoothing: antialiased;
          }
        `}
      </style>
      <App ctx={ctx} data={data} />
    </>,
  );
}

/**
 * Loads required fonts and CSS with appropriate fallbacks
 * @returns {Promise} Resolves when fonts are loaded or timeout occurs
 */
async function loadFonts(ctx) {
  // Import all CSS files in parallel
  const cssPromises = [
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap",
    ),
    ctx.importCSS(
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap",
    ),
    ctx.importCSS("main.css"),
  ];

  // Add style to ensure consistent rendering
  const fontStylesheet = document.createElement("style");
  fontStylesheet.textContent = `
    @font-face {
      font-family: 'JetBrains Mono';
      font-display: block;
    }
    * {
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
  `;
  document.head.appendChild(fontStylesheet);

  // Force font loading with invisible element
  const fontPreloader = document.createElement("div");
  fontPreloader.setAttribute("aria-hidden", "true");
  fontPreloader.style.cssText = `
    position: absolute;
    visibility: hidden;
    pointer-events: none;
    left: -9999px;
    font-family: 'JetBrains Mono', monospace;
  `;
  fontPreloader.innerHTML =
    "<span style=\"font-family:'JetBrains Mono'\">Font preload</span>";
  document.body.appendChild(fontPreloader);

  // Wait for CSS imports to complete
  await Promise.all(cssPromises);

  // Use consistent timeout (no browser detection needed)
  // This is sufficient for all browsers and simplifies the code
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
    document.head.removeChild(fontStylesheet);
  }
}

export async function init(ctx, data) {
  if (areFontsLoaded()) {
    renderApp(ctx, data);
    return;
  }

  const placeholder = createLoadingPlaceholder();
  ctx.root.appendChild(placeholder);

  try {
    await loadFonts(ctx);

    ctx.root.removeChild(placeholder);

    renderApp(ctx, data);
  } catch (error) {
    console.error("Error initializing data table:", error);

    // Clean up and fallback render
    try {
      ctx.root.removeChild(placeholder);
    } catch (e) {
      // Ignore if already removed
    }

    renderApp(ctx, data);
  }
}
