import "./main.css";

import React from "react";
import { createRoot } from "react-dom/client";

import App from "./App";

export function init(ctx, payload) {
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap",
  );
  ctx.importCSS("main.css");

  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} payload={payload} />);
}
