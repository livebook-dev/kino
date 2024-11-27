import "./main.css";
import "@glideapps/glide-data-grid/dist/index.css";

import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";

export async function init(ctx, data) {
  // In Firefox and Safari, during the first load (uncached), the data
  // grid renders the default font and the font is only updated after
  // hovering the grid. Ensuring the font is loaded helps in Firefox.
  await ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap",
  );
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap",
  );
  ctx.importCSS("main.css");

  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} data={data} />);
}
