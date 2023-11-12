import "./main.css";

import React from "react";
import { createRoot } from "react-dom/client";

import App from "./components/App";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css"
  );

  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} payload={payload} />);
}
