import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";

export async function init(ctx, data) {
  // Create a beautiful loading placeholder with shimmer effect
  const placeholder = document.createElement("div");
  placeholder.className = "font-loading-placeholder";
  
  // Add data table info header (similar to what's shown above the actual table)
  const topBar = document.createElement("div");
  topBar.style.padding = "12px 16px";
  topBar.style.display = "flex";
  topBar.style.alignItems = "center";
  
  // Add table info shimmer
  const tableInfo = document.createElement("div");
  tableInfo.className = "shimmer";
  tableInfo.style.width = "150px";
  tableInfo.style.height = "22px";
  tableInfo.style.borderRadius = "4px";
  topBar.appendChild(tableInfo);
  
  // Add spacer
  const spacer = document.createElement("div");
  spacer.style.flexGrow = "1";
  topBar.appendChild(spacer);
  
  // Add buttons shimmer for the top toolbar
  for (let i = 0; i < 3; i++) {
    const button = document.createElement("div");
    button.className = "shimmer";
    button.style.width = "36px";
    button.style.height = "36px";
    button.style.borderRadius = "4px";
    button.style.marginLeft = "12px";
    topBar.appendChild(button);
  }
  
  // Create header with shimmer elements for column headers
  const header = document.createElement("div");
  header.className = "data-table-loading-header";
  
  // Add shimmer title blocks to represent column headers
  for (let i = 0; i < 4; i++) {
    const title = document.createElement("div");
    title.className = "shimmer shimmer-title";
    // Vary the widths for more realistic appearance
    if (i === 0) title.style.width = "60px";
    if (i === 1) title.style.width = "120px";
    if (i === 2) title.style.width = "160px";
    if (i === 3) title.style.width = "140px";
    header.appendChild(title);
  }
  
  // Add spinner
  const spinner = document.createElement("div");
  spinner.className = "loading-spinner";
  header.appendChild(spinner);
  
  // Create table body with shimmer rows
  const body = document.createElement("div");
  body.className = "data-table-loading-body";
  
  // Create 7 rows with shimmer cells of varying widths
  for (let i = 0; i < 7; i++) {
    const row = document.createElement("div");
    row.className = "shimmer-row";
    
    // Add index cell (narrow)
    const indexCell = document.createElement("div");
    indexCell.className = "shimmer shimmer-cell shimmer-cell-1";
    row.appendChild(indexCell);
    
    // Add data cells with varying widths
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
  ctx.root.appendChild(placeholder);

  // Start loading CSS files
  const cssPromises = [
    ctx.importCSS("https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"),
    ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"),
    ctx.importCSS("main.css")
  ];

  try {
    // Check if Safari has cached fonts to avoid showing loading state unnecessarily
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    const safariHasCachedFonts = isSafari && 
      (document.fonts && Array.from(document.fonts).some(font => 
        font.family.includes('JetBrains Mono') && font.loaded
      ));
    
    // On Safari after a refresh, if fonts are already cached, skip the loading state
    // We'll test this by attempting to immediately render without placeholder
    if (isSafari && safariHasCachedFonts) {
      console.log("Safari refresh detected with cached fonts, skipping loading state");
      // Remove the placeholder
      ctx.root.removeChild(placeholder);
      
      // Create and render the actual app immediately
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
        </>
      );
      
      // Early return to skip the loading process
      return;
    }
    
    // For initial loads or non-Safari browsers, continue with normal font loading
    const fontStylesheet = document.createElement("style");
    fontStylesheet.textContent = `
      @font-face {
        font-family: 'JetBrains Mono';
        font-display: block;
        src: url('https://fonts.gstatic.com/s/jetbrainsmono/v18/tDbY2o-flEEny0FZhsfKu5WU4zr3E_BX0PnT8RD8yKxTOlOV.woff2') format('woff2');
      }
      
      * {
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }
    `;
    document.head.appendChild(fontStylesheet);

    // Create inline font styles to force Safari to load fonts immediately
    const fontPreloader = document.createElement("div");
    fontPreloader.setAttribute("aria-hidden", "true");
    fontPreloader.style.cssText = `
      position: absolute;
      visibility: hidden;
      pointer-events: none;
      left: -9999px;
      opacity: 0;
      font-family: 'JetBrains Mono', monospace;
      font-weight: 400;
    `;
    // Add a diverse set of characters to ensure font is fully loaded
    fontPreloader.innerHTML = `
      <span style="font-family: 'JetBrains Mono'; font-weight: 400">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-=_+[]{}|;':,./<>?</span>
      <span style="font-family: 'JetBrains Mono'; font-weight: 500">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789</span>
      <span style="font-family: 'JetBrains Mono'; font-weight: 600">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789</span>
      <span style="font-family: 'Inter'; font-weight: 400">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789</span>
      <span style="font-family: 'Inter'; font-weight: 500">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789</span>
    `;
    document.body.appendChild(fontPreloader);

    // Wait for all CSS imports to complete
    await Promise.all(cssPromises);

    // Force font loading with more aggressive techniques
    if (document.fonts && typeof document.fonts.ready === "object") {
      // Load fonts with timeout for Safari
      const fontLoadPromise = document.fonts.ready;
      const timeoutPromise = new Promise(resolve => setTimeout(resolve, 800)); // Safari needs more time
      await Promise.race([fontLoadPromise, timeoutPromise]);
      
      // Additional check to ensure the font is loaded in Safari
      if (isSafari && !safariHasCachedFonts) {
        // Safari-specific handling - draw text to force font loading
        const canvas = document.createElement("canvas");
        canvas.width = 500;
        canvas.height = 50;
        const ctx = canvas.getContext("2d");
        ctx.font = "14px 'JetBrains Mono'";
        ctx.fillText("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", 10, 25);
        // Wait a bit more for Safari
        await new Promise(resolve => setTimeout(resolve, 200));
      }
    } else {
      // Fallback with a small timeout for older browsers
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    // Clean up the preloader and placeholder
    document.body.removeChild(fontPreloader);
    document.head.removeChild(fontStylesheet);
    ctx.root.removeChild(placeholder);

    // Create and render the actual app
    const root = createRoot(ctx.root);
    
    // Render with proper fonts enforced in style
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
      </>
    );
  } catch (error) {
    console.error("Error loading fonts:", error);
    // Fallback to rendering without waiting for fonts
    try {
      ctx.root.removeChild(placeholder);
    } catch (e) {
      // Ignore if already removed
    }
    const root = createRoot(ctx.root);
    root.render(<App ctx={ctx} data={data} />);
  }
}
