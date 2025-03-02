import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";

/**
 * Creates a skeleton loading UI for the data table
 */
function createLoadingPlaceholder() {
  const placeholder = document.createElement("div");
  placeholder.className = "font-loading-placeholder";

  // Add toolbar with shimmer elements
  const topBar = document.createElement("div");
  topBar.style.padding = "12px 16px";
  topBar.style.display = "flex";
  topBar.style.alignItems = "center";

  // Info shimmer
  const tableInfo = document.createElement("div");
  tableInfo.className = "shimmer";
  tableInfo.style.width = "150px";
  tableInfo.style.height = "22px";
  tableInfo.style.borderRadius = "4px";
  topBar.appendChild(tableInfo);

  // Spacer
  const spacer = document.createElement("div");
  spacer.style.flexGrow = "1";
  topBar.appendChild(spacer);

  // Action buttons shimmer
  for (let i = 0; i < 3; i++) {
    const button = document.createElement("div");
    button.className = "shimmer";
    button.style.width = "36px";
    button.style.height = "36px";
    button.style.borderRadius = "4px";
    button.style.marginLeft = "12px";
    topBar.appendChild(button);
  }

  // Header with column titles
  const header = document.createElement("div");
  header.className = "data-table-loading-header";

  // Column header shimmer blocks
  const columnWidths = [60, 120, 160, 140]; // Varied widths for realism
  for (let i = 0; i < columnWidths.length; i++) {
    const title = document.createElement("div");
    title.className = "shimmer shimmer-title";
    title.style.width = `${columnWidths[i]}px`;
    header.appendChild(title);
  }

  // Loading spinner
  const spinner = document.createElement("div");
  spinner.className = "loading-spinner";
  header.appendChild(spinner);

  // Table body with rows
  const body = document.createElement("div");
  body.className = "data-table-loading-body";

  // Create shimmer rows with cells
  for (let i = 0; i < 7; i++) {
    const row = document.createElement("div");
    row.className = "shimmer-row";

    // Index cell
    const indexCell = document.createElement("div");
    indexCell.className = "shimmer shimmer-cell shimmer-cell-1";
    row.appendChild(indexCell);

    // Data cells
    for (let j = 2; j <= 5; j++) {
      const cell = document.createElement("div");
      cell.className = `shimmer shimmer-cell shimmer-cell-${j}`;
      row.appendChild(cell);
    }

    body.appendChild(row);
  }

  // Assemble the placeholder
  placeholder.appendChild(topBar);
  placeholder.appendChild(header);
  placeholder.appendChild(body);

  return placeholder;
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
 * Detects if the current browser is Safari
 * @returns {boolean} True if Safari, false otherwise
 */
function isSafari() {
  return /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
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
  // Skip loading UI if fonts are already fully loaded
  if (areFontsLoaded()) {
    renderApp(ctx, data);
    return;
  }

  // Show loading skeleton when fonts aren't loaded yet
  const placeholder = createLoadingPlaceholder();
  ctx.root.appendChild(placeholder);

  try {
    // Load fonts and wait for them to be ready
    await loadFonts(ctx);

    // Remove loading placeholder
    ctx.root.removeChild(placeholder);

    // Render the app
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
