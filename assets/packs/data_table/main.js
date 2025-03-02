import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";

/**
 * Creates a table-based skeleton loading UI for the data table that closely matches the final layout
 * @param {Object} options Configuration options for the placeholder
 * @param {number} options.columnCount Number of columns to show (defaults to detected or 5)
 * @param {number} options.rowCount Number of rows to show (defaults to 6)
 * @returns {HTMLElement} The placeholder element
 */
function createLoadingPlaceholder(options = {}) {
  // Try to detect a reasonable number of columns from previous renders or URL params
  const urlParams = new URLSearchParams(window.location.search);
  const debugColumns = urlParams.get("debugColumns");

  // Get column count with fallbacks
  const columnCount =
    options.columnCount ||
    (debugColumns ? parseInt(debugColumns) : null) ||
    (document.querySelector(".gdg-data")
      ? document.querySelector(".gdg-data").childElementCount
      : null) ||
    5;

  // Get row count with fallbacks
  const rowCount =
    options.rowCount ||
    (urlParams.get("debugRows")
      ? parseInt(urlParams.get("debugRows"))
      : null) ||
    6;

  // Column width mapping function
  function getColumnWidth(index) {
    // First column is usually narrow (like an ID column)
    if (index === 0) return "w-12";

    const widths = ["w-32", "w-48", "w-24", "w-20", "w-28", "w-36"];
    return widths[(index - 1) % widths.length];
  }

  // Create main container
  const placeholder = document.createElement("div");
  placeholder.className = "font-loading-placeholder";

  // Create inner container
  const container = document.createElement("div");
  container.className = "shimmer-container";

  // Create toolbar
  const toolbar = document.createElement("div");
  toolbar.className = "shimmer-toolbar";

  // Toolbar left side (info)
  const toolbarLeft = document.createElement("div");
  toolbarLeft.className = "shimmer-toolbar-left";

  const tableInfo = document.createElement("div");
  tableInfo.className = "shimmer shimmer-table-info";
  toolbarLeft.appendChild(tableInfo);

  // Toolbar right side (buttons)
  const toolbarRight = document.createElement("div");
  toolbarRight.className = "shimmer-toolbar-right";

  // Add action buttons (search, download, etc.)
  for (let i = 0; i < 3; i++) {
    const button = document.createElement("div");
    button.className = "shimmer shimmer-button";
    toolbarRight.appendChild(button);
  }

  toolbar.appendChild(toolbarLeft);
  toolbar.appendChild(toolbarRight);
  container.appendChild(toolbar);

  // Create table container
  const tableContainer = document.createElement("div");
  tableContainer.className = "shimmer-table-container";

  // Create table structure
  const table = document.createElement("table");
  table.className = "shimmer-table";

  // Create header
  const thead = document.createElement("thead");
  const headerRow = document.createElement("tr");

  for (let i = 0; i < columnCount; i++) {
    const th = document.createElement("th");
    const shimmerDiv = document.createElement("div");
    shimmerDiv.className = `shimmer header-shimmer ${getColumnWidth(i)}`;
    th.appendChild(shimmerDiv);
    headerRow.appendChild(th);
  }

  thead.appendChild(headerRow);
  table.appendChild(thead);

  // Create table body
  const tbody = document.createElement("tbody");

  for (let i = 0; i < rowCount; i++) {
    const row = document.createElement("tr");

    for (let j = 0; j < columnCount; j++) {
      const td = document.createElement("td");
      const shimmerDiv = document.createElement("div");
      shimmerDiv.className = `shimmer ${getColumnWidth(j)}`;
      td.appendChild(shimmerDiv);
      row.appendChild(td);
    }

    tbody.appendChild(row);
  }

  table.appendChild(tbody);
  tableContainer.appendChild(table);
  container.appendChild(tableContainer);

  // Create pagination footer
  const pagination = document.createElement("div");
  pagination.className = "shimmer-pagination";

  // Pagination info
  const paginationInfo = document.createElement("div");
  paginationInfo.className = "shimmer shimmer-pagination-info";
  pagination.appendChild(paginationInfo);

  // Pagination controls
  const paginationControls = document.createElement("div");
  paginationControls.className = "shimmer-pagination-controls";

  // Add pagination buttons
  for (let i = 0; i < 3; i++) {
    const button = document.createElement("div");
    button.className = "shimmer shimmer-pagination-button";
    paginationControls.appendChild(button);
  }

  pagination.appendChild(paginationControls);
  container.appendChild(pagination);

  placeholder.appendChild(container);
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
