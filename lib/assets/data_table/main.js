import "@glideapps/glide-data-grid/dist/index.css";
import React, { useCallback, useEffect, useState } from "react";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
} from "@glideapps/glide-data-grid";
import { createRoot } from "react-dom/client";
import {
  RiRefreshLine,
  RiArrowLeftSLine,
  RiArrowRightSLine,
  RiSearch2Line,
} from "react-icons/ri";
import "./main.css";

export function init(ctx, data) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );

  const customHeaderIcons = {
    arrowUp: (
      p
    ) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20">
      <path fill="${p.fgColor}" d="M0 0h24v24H0z"/>
      <path fill="${p.bgColor}" d="M12 2c5.52 0 10 4.48 10 10s-4.48 10-10 10S2 17.52 2 12 6.48 2 12 2zm1 10h3l-4-4-4 4h3v4h2v-4z"/>
    </svg>`,
    arrowDown: (
      p
    ) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20">
      <path fill="${p.fgColor}" d="M0 0h24v24H0z"/>
      <path fill="${p.bgColor}" d="M12 2c5.52 0 10 4.48 10 10s-4.48 10-10 10S2 17.52 2 12 6.48 2 12 2zm1 10V8h-2v4H8l4 4 4-4h-3z"/>
    </svg>`,
  };

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

  const theme = {
    fontFamily: "JetBrains Mono",
    bgHeader: "white",
    textDark: "#61758a",
    textHeader: "#304254",
    headerFontStyle: "bold 14px",
    baseFontStyle: "14px",
    borderColor: "#E1E8F0",
    horizontalBorderColor: "#E1E8F0",
    accentColor: "#3E64FF",
    accentLight: "#ECF0FF",
    bgHeaderHovered: "#F0F5F9",
    bgHeaderHasFocus: "#E1E8F0",
    bgSearchResult: "#FFF7EC",
  };

  const columnWidth = {
    text: 300,
    number: 150,
    uri: 250,
    date: 150,
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
  const hasData = data.content.columns.length !== 0;
  const totalRows = data.content.total_rows;

  const hasPagination =
    data.features.includes("pagination") &&
    (totalRows === null || totalRows > 0);

  function Refetch() {
    const refetch = () => {
      ctx.pushEvent("refetch");
    };

    return (
      <button class="icon-button" aria-label="refresh" onClick={refetch}>
        <RiRefreshLine />
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
          <label class="input-label">Show</label>
          <select class="input" value={limit} onChange={handleChange}>
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
          <RiArrowLeftSLine />
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
          <RiArrowRightSLine />
        </button>
      </div>
    );
  }

  function App() {
    const [content, setContent] = useState(data.content);
    const [showSearch, setShowSearch] = React.useState(false);
    const [headers, setHeaders] = useState(columns);

    const onSearchClose = React.useCallback(() => setShowSearch(false), []);

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

    const orderBy = (colIndex) => {
      const newKey = columns[colIndex].id;
      const [key, order] = reorder(content.order_by, content.order, newKey);
      ctx.pushEvent("order_by", { key, order });
    };

    const toggleSearch = () => {
      setShowSearch(!showSearch);
    };

    useEffect(() => {
      ctx.handleEvent("update_content", (content) => {
        setContent(content);
      });
    }, []);

    useEffect(() => {
      const icon = content.order === "asc" ? "arrowUp" : "arrowDown";
      const newHeaders = headers.map((header) => {
        if (header.id === content.order_by) {
          return { ...header, overlayIcon: icon };
        } else {
          return { ...header, overlayIcon: null };
        }
      });
      setHeaders(newHeaders);
    }, [content]);

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
          <span class="tooltip right" data-tooltip="Current page search">
            <button
              class="icon-button search"
              aria-label="search"
              onClick={toggleSearch}
            >
              <RiSearch2Line />
            </button>
          </span>
          <Limit limit={content.limit} />
          {hasPagination && (
            <Pagination page={content.page} maxPage={content.max_page} />
          )}
        </div>
        {hasData && (
          <DataEditor
            className={"table-container"}
            theme={theme}
            getCellContent={getData}
            columns={headers}
            rows={rows}
            width={896}
            height={height}
            rowHeight={44}
            headerHeight={44}
            verticalBorder={false}
            rowMarkers={"both"}
            onHeaderClicked={orderBy}
            showSearch={showSearch}
            getCellsForSelection={true}
            onSearchClose={onSearchClose}
            headerIcons={customHeaderIcons}
          />
        )}
        {!hasData && <p class="no-data">No data</p>}
        <div id="portal" />
      </div>
    );
  }

  const container = document.getElementById("root");
  const root = createRoot(container);
  root.render(<App />);
}

function reorder(orderBy, order, key) {
  if (orderBy === key) {
    if (order === "asc") {
      return [key, "desc"];
    } else {
      return [null, "asc"];
    }
  } else {
    return [key, "asc"];
  }
}
