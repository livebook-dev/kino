import "./main.css";

import React from "react";
import { createRoot } from "react-dom/client";

import App from "./App";

export function init(ctx, tree) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap",
  );

  const root = createRoot(ctx.root);
  root.render(<App tree={tree} />);
}
