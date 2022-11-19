import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
} from "@glideapps/glide-data-grid";
import {
  RiRefreshLine,
  RiArrowLeftSLine,
  RiArrowRightSLine,
  RiSearch2Line,
} from "react-icons/ri";

import "@glideapps/glide-data-grid/dist/index.css";
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

  const columnsInitData = data.content.columns.map((column) => {
    return {
      title: column.label,
      id: column.key,
      width: columnWidth[column.type],
      icon: headerIcons[column.type],
    };
  });

  const columnsInitSize = columnsInitData.map((column) => {
    return { [column.title]: column.width };
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
      <button className="icon-button" aria-label="refresh" onClick={refetch}>
        <RiRefreshLine />
      </button>
    );
  }

  function Search({ toggleSearch }) {
    return (
      <span className="tooltip right" data-tooltip="Current page search">
        <button
          className="icon-button search"
          aria-label="search"
          onClick={toggleSearch}
        >
          <RiSearch2Line />
        </button>
      </span>
    );
  }

  function Limit({ limit }) {
    const handleChange = (event) => {
      ctx.pushEvent("limit", { limit: parseInt(event.target.value) });
    };

    return (
      <div>
        <form>
          <label className="input-label">Show</label>
          <select className="input" value={limit} onChange={handleChange}>
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
        <button
          className="pagination__button"
          onClick={prev}
          disabled={page === 1}
        >
          <RiArrowLeftSLine />
          <span>Prev</span>
        </button>
        <div className="pagination__info">
          <span>
            {page} of {maxPage || "?"}
          </span>
        </div>
        <button
          className="pagination__button"
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
    const [showSearch, setShowSearch] = useState(false);
    const [columns, setColumns] = useState(columnsInitData);
    const [colSizes, setColSizes] = useState(columnsInitSize);

    const infiniteScroll = content.limit === totalRows;
    const height = totalRows >= 10 && infiniteScroll ? 484 : null;

    const rows =
      content.page === content.max_page && !infiniteScroll
        ? totalRows % content.limit
        : content.limit;

    const getData = useCallback(
      ([col, row]) => {
        const rawData = content.rows[row].fields[col];
        const kind = cellKind[content.columns[col].type];

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

    const toggleSearch = () => {
      setShowSearch(!showSearch);
    };

    const orderBy = (colIndex) => {
      const newKey = columns[colIndex].id;
      const [key, order] = reorder(content.order_by, content.order, newKey);
      ctx.pushEvent("order_by", { key, order });
    };

    const onColumnResize = useCallback((column, newSize) => {
      setColSizes((prevColSizes) => {
        return {
          ...prevColSizes,
          [column.title]: newSize,
        };
      });
    }, []);

    useEffect(() => {
      ctx.handleEvent("update_content", (content) => {
        setContent(content);
      });
    }, []);

    useEffect(() => {
      const icon = content.order === "asc" ? "arrowUp" : "arrowDown";
      const newColumns = columns.map((header) => {
        if (header.id === content.order_by) {
          return { ...header, overlayIcon: icon };
        } else {
          return { ...header, overlayIcon: null };
        }
      });
      setColumns(newColumns);
    }, [content]);

    useEffect(() => {
      const newColumns = columns.map((header) => {
        return { ...header, width: colSizes[header.title] };
      });
      setColumns(newColumns);
    }, [colSizes]);

    return (
      <div className="app">
        <div className="navigation">
          <div className="navigation__info">
            <h2 className="navigation__name">{data.name}</h2>
            <span className="navigation__details">
              {totalRows || "?"} entries
            </span>
          </div>
          <div className="navigation__space"></div>
          {hasRefetch && <Refetch />}
          <Search toggleSearch={toggleSearch} />
          <Limit limit={content.limit} />
          {hasPagination && (
            <Pagination page={content.page} maxPage={content.max_page} />
          )}
        </div>
        {hasData && (
          <DataEditor
            className="table-container"
            theme={theme}
            getCellContent={getData}
            columns={columns}
            rows={rows}
            width="100%"
            height={height}
            rowHeight={44}
            headerHeight={44}
            verticalBorder={false}
            rowMarkers="both"
            onHeaderClicked={orderBy}
            showSearch={showSearch}
            getCellsForSelection={true}
            onSearchClose={toggleSearch}
            headerIcons={customHeaderIcons}
            overscrollX={100}
            isDraggable={false}
            smoothScrollX={true}
            smoothScrollY={true}
            onColumnResize={onColumnResize}
          />
        )}
        {!hasData && <p className="no-data">No data</p>}
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
