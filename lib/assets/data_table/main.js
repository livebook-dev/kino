import "@glideapps/glide-data-grid/dist/index.css";
import React, { useCallback, useEffect, useState } from "react";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
} from "@glideapps/glide-data-grid";
import { createRoot } from "react-dom/client";
import "./main.css";

export function init(ctx, data) {
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

  const hasRefetch = data.features.includes("refetch");

  const totalRows = data.content.total_rows;

  const hasPagination =
    data.features.includes("pagination") &&
    (totalRows === null || totalRows > 0);

  function Refetch() {
    const refetch = () => {
      ctx.pushEvent("refetch");
    };

    return (
      <button
        v-if="data.features.includes('refetch')"
        class="icon-button"
        aria-label="refresh"
        onClick={refetch}
      >
        <i class="ri ri-refresh-line"></i>
      </button>
    );
  }

  function Limit({ limit }) {
    const handleChange = (event) => {
      ctx.pushEvent("limit", { limit: parseInt(event.target.value) });
    };

    return (
      <div>
        <form>
          <select value={limit} onChange={handleChange}>
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="20">20</option>
            <option value={totalRows}>All</option>
          </select>
        </form>
      </div>
    );
  }

  function Pagination({ page, maxPage }) {
    const prev = () => {
      ctx.pushEvent("show_page", { page: page - 1 });
    };

    const next = () => {
      ctx.pushEvent("show_page", { page: page + 1 });
    };

    return (
      <div className="pagination">
        <button class="pagination__button" onClick={prev} disabled={page === 1}>
          <i class="ri ri-arrow-left-s-line"></i>
          <span>Prev</span>
        </button>
        <div class="pagination__info">
          <span>
            {page} of {maxPage || "?"}
          </span>
        </div>
        <button
          class="pagination__button"
          onClick={next}
          disabled={page === maxPage}
        >
          <span>Next</span>
          <i class="ri ri-arrow-right-s-line"></i>
        </button>
      </div>
    );
  }

  function App() {
    const [content, setContent] = useState(data.content);

    const infiniteScroll = content.limit === totalRows;
    const height = totalRows >= 10 && infiniteScroll ? 484 : null;

    const rows =
      content.page === content.max_page && !infiniteScroll
        ? totalRows % content.limit
        : content.limit;

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
        <div className="navigation">
          <div class="navigation__info">
            <h2 class="navigation__name">{data.name}</h2>
            <span class="navigation__details">
              {data.content.total_rows || "?"} entries
            </span>
          </div>
          <div class="navigation__space"></div>
          {hasRefetch && <Refetch />}
          <Limit limit={content.limit} />
          {hasPagination && (
            <Pagination page={content.page} maxPage={content.max_page} />
          )}
        </div>
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
          height={height}
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
