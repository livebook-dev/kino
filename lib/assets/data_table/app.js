import "@glideapps/glide-data-grid/dist/index.css";
import React, { useCallback, useEffect, useState } from "react";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
} from "@glideapps/glide-data-grid";
import { createRoot } from "react-dom/client";

export function init(ctx, data) {
  ctx.importCSS("app.css");
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css"
  );

  const headerIcons = {
    text: GridColumnIcon.HeaderString,
    number: GridColumnIcon.HeaderNumber,
    uri: GridColumnIcon.HeaderUri,
    date: GridColumnIcon.HeaderDate,
  };

  const cellKind = {
    text: GridCellKind.Text,
    number: GridCellKind.Number,
    uri: GridCellKind.Uri,
    date: GridCellKind.Text,
  };

  const columnWidth = {
    text: 300,
    number: 125,
    uri: 200,
    date: 125,
  };

  const columns = data.content.columns.map((column) => {
    return {
      title: column.label,
      id: column.key,
      width: columnWidth[column.type],
      icon: headerIcons[column.type],
    };
  });

  function Navigation({ page }) {
    const prev = () => {
      ctx.pushEvent("show_page", { page: page - 1 });
    };

    const next = () => {
      ctx.pushEvent("show_page", { page: page + 1 });
    };

    return (
      <div className="navigation">
        <div class="navigation__info">
          <h2 class="navigation__name">{data.name}</h2>
          <span class="navigation__details">
            {data.content.total_rows || "?"} entries
          </span>
        </div>
        <div class="navigation__space"></div>
        {/* Actions */}
        {/* Pagination */}
        <div className="pagination">
          <button class="pagination__button" onClick={prev}>
            <i class="ri ri-arrow-left-s-line"></i>
            <span>Prev</span>
          </button>
          <div class="pagination__info">
            <span>
              {page} of {data.content.max_page || "?"}
            </span>
          </div>
          <button class="pagination__button" onClick={next}>
            <span>Next</span>
            <i class="ri ri-arrow-right-s-line"></i>
          </button>
        </div>
      </div>
    );
  }

  function App() {
    const [content, setContent] = useState(data.content);

    const rows =
      content.page === data.content.max_page
        ? data.content.total_rows % 10
        : 10;

    const getData = useCallback(
      ([col, row]) => {
        const dataRow = content.rows[row];
        const rawData = Object.values(dataRow)[0][col];
        const type = data.content.columns[col].type;
        const kind = cellKind[type];
        const cellData = rawData.startsWith('"')
          ? rawData.slice(1, -1)
          : rawData;
        return {
          kind: kind,
          data: cellData,
          displayData: cellData,
          allowOverlay: true,
          allowWrapping: true,
          readonly: true,
        };
      },
      [content]
    );

    useEffect(() => {
      ctx.handleEvent("update_content", (content) => {
        setContent(content);
      });
    }, []);

    return (
      <div className="app">
        <Navigation page={content.page} />
        <DataEditor
          className={"table-container"}
          theme={{
            fontFamily: "JetBrains Mono",
            bgHeader: "white",
            textDark: "#61758a",
            textHeader: "#304254",
            headerFontStyle: "bold 14px",
            baseFontStyle: "14px",
            borderColor: "#e1e8f0",
            horizontalBorderColor: "#e1e8f0",
          }}
          getCellContent={getData}
          columns={columns}
          rows={rows}
          width={896}
          rowHeight={44}
          headerHeight={44}
          verticalBorder={false}
          rowMarkers={"number"}
        />
        <div id="portal" />
      </div>
    );
  }

  const container = document.getElementById("root");
  const root = createRoot(container);
  root.render(<App />);
}
