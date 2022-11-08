import "@glideapps/glide-data-grid/dist/index.css";
import React, { useCallback } from "react";
import DataEditor, { GridCellKind } from "@glideapps/glide-data-grid";
import { createRoot } from "react-dom/client";

export function init(ctx, data) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css"
  );

  const columns = data.content.columns.map((column) => {
    return { title: column.label, id: column.key };
  });

  const rows = data.content.total_rows > 10 ? 10 : data.content.total_rows;

  function App() {
    const getData = useCallback(([col, row]) => {
      const dataRow = data.content.rows[row];
      const d = Object.values(dataRow)[0][col];
      return {
        kind: GridCellKind.Text,
        data: d,
        displayData: d.toString(),
        allowOverlay: false,
      };
    }, []);

    return (
      <div className="App">
        <DataEditor getCellContent={getData} columns={columns} rows={rows} />
        <div id="portal" />
      </div>
    );
  }

  const container = document.getElementById("root");
  const root = createRoot(container);
  root.render(<App />);
}
