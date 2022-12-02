import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
  CompactSelection,
} from "@glideapps/glide-data-grid";
import {
  RiRefreshLine,
  RiArrowLeftSLine,
  RiArrowRightSLine,
  RiSearch2Line,
} from "react-icons/ri";
import { useLayer } from "react-laag";

import "@glideapps/glide-data-grid/dist/index.css";
import "./main.css";

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
  headerIconSize: 22,
};

export function init(ctx, data) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );

  const root = createRoot(ctx.root);
  root.render(<App ctx={ctx} data={data} />);
}

function App({ ctx, data }) {
  const columnsInitData = data.content.columns.map((column) => {
    return {
      title: column.label,
      id: column.key,
      icon: headerIcons[column.type] || GridCellKind.Text,
      hasMenu: true,
      summary: data.content.summary?.[column.key],
    };
  });

  const columnsInitSize = columnsInitData.map((column) => {
    return { [column.title]: 250 };
  });

  const hasRefetch = data.features.includes("refetch");
  const hasData = data.content.columns.length !== 0;
  const totalRows = data.content.total_rows;

  const hasPagination =
    data.features.includes("pagination") &&
    (totalRows === null || totalRows > 0);

  const [content, setContent] = useState(data.content);
  const [showSearch, setShowSearch] = useState(false);
  const [columns, setColumns] = useState(columnsInitData);
  const [colSizes, setColSizes] = useState(columnsInitSize);
  const [menu, setMenu] = useState(null);
  const [showMenu, setShowMenu] = useState(false);
  const [selection, setSelection] = useState({
    rows: CompactSelection.empty(),
    columns: CompactSelection.empty(),
  });

  const infiniteScroll = content.limit === totalRows;
  const height = totalRows >= 10 && infiniteScroll ? 484 : null;
  const rowMarkerStartIndex = (content.page - 1) * content.limit + 1;
  const headerHeight = content.summary ? 132 : 44;

  const rows =
    content.page === content.max_page && !infiniteScroll
      ? totalRows % content.limit
      : content.limit;

  const drawHeader = useCallback((args) => {
    const {
      ctx,
      theme,
      rect,
      column,
      menuBounds,
      isHovered,
      isSelected,
      spriteManager,
    } = args;

    if (column.sourceIndex === 0) {
      return true;
    }

    ctx.rect(rect.x, rect.y, rect.width, rect.height);

    const fillStyle = isSelected ? theme.textHeaderSelected : theme.textHeader;
    const fillInfoStyle = isSelected ? theme.accentLight : theme.textDark;
    const shouldDrawMenu = column.hasMenu === true && isHovered;
    const hasSummary = column.summary ? true : false;

    if (shouldDrawMenu && rect.width > 35) {
      const fadeWidth = 35;
      const fadeStart = rect.width - fadeWidth;
      const fadeEnd = rect.width - fadeWidth * 0.7;

      const fadeStartPercent = fadeStart / rect.width;
      const fadeEndPercent = fadeEnd / rect.width;

      const grad = ctx.createLinearGradient(rect.x, 0, rect.x + rect.width, 0);
      const trans = "rgba(48, 66, 84, 0)";

      grad.addColorStop(0, fillStyle);
      grad.addColorStop(fadeStartPercent, fillStyle);
      grad.addColorStop(fadeEndPercent, trans);
      grad.addColorStop(1, trans);
      ctx.fillStyle = grad;
  } else {
      ctx.fillStyle = fillStyle;
  }

    if (column.icon) {
      const variant = isSelected
        ? "selected"
        : column.style === "highlight"
        ? "special"
        : "normal";

      const headerSize = theme.headerIconSize;

      spriteManager.drawSprite(
        column.icon,
        variant,
        ctx,
        rect.x + 10,
        rect.y + 10,
        headerSize,
        theme
      );

      if (column.overlayIcon) {
        spriteManager.drawSprite(
          column.overlayIcon,
          isSelected ? "selected" : "special",
          ctx,
          rect.x + 19,
          rect.y + 19,
          18,
          theme
        );
      }
    }

    ctx.fillText(
      column.title,
      menuBounds.x - rect.width + theme.headerIconSize * 2.5 + 14,
      hasSummary
        ? menuBounds.y - (theme.headerIconSize + 8)
        : menuBounds.y + menuBounds.height / 2
    );

    if (hasSummary) {
      const numericInfo = {
        Min: column.summary.min ?? 0,
        Max: column.summary.max ?? 0,
        Mean: column.summary.mean ?? 0,
        Nulls: column.summary.nulls ?? "",
      };

      const categoricalInfo = {
        Unique: column.summary.unique ?? 0,
        Top: column.summary.top ?? "",
        "Top freq": column.summary.freq ?? "",
        Nulls: column.summary.nulls ?? 0,
      };

      const summaryData =
        column.summary.kind === "categorical" ? categoricalInfo : numericInfo;

      ctx.fillStyle = fillInfoStyle;
      Object.entries(summaryData).forEach(([key, value], index) => {
        ctx.font = "bold 14px JetBrains Mono";
        ctx.fillText(`${key}:`, rect.x + 12, rect.y + 8 * 3 * (index + 1) + 24);
        ctx.font = "14px JetBrains Mono";
        ctx.fillText(
          value,
          rect.x + ctx.measureText(key).width + 24,
          rect.y + 8 * 3 * (index + 1) + 24
        );
      });
    }

    if (shouldDrawMenu) {
      const arrowX = menuBounds.x + menuBounds.width / 2 - 5.5;
      const arrowY = hasSummary
        ? menuBounds.y + menuBounds.height / 2 - 3
        : rect.height / 4;
      const p = new Path2D("M12 16l-6-6h12z");
      ctx.translate(arrowX - 8, arrowY);
      ctx.fill(p);
    }

    return true;
  }, []);

  const getData = useCallback(
    ([col, row]) => {
      const cellData = content.rows[row].fields[col];
      const kind = cellKind[content.columns[col].type] || GridCellKind.Text;

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

  const orderBy = (order) => {
    const key = order ? columns[menu.column].id : null;
    ctx.pushEvent("order_by", { key, order: order ?? "asc" });
  };

  const selectAllCurrent = () => {
    const newSelection = {
      ...selection,
      columns: CompactSelection.fromSingleSelection(menu.column),
    };
    setSelection(newSelection);
  };

  const { layerProps, renderLayer } = useLayer({
    isOpen: showMenu,
    auto: true,
    placement: "bottom-end",
    possiblePlacements: ["bottom-end", "bottom-center", "bottom-start"],
    triggerOffset: 0,
    onOutsideClick: () => setMenu(null),
    trigger: {
      getBounds: () => ({
        left: menu?.bounds.x ?? 0,
        top: menu?.bounds.y ?? 0,
        width: menu?.bounds.width ?? 0,
        height: menu?.bounds.height ?? 0,
        right: (menu?.bounds.x ?? 0) + (menu?.bounds.width ?? 0),
        bottom: (menu?.bounds.y ?? 0) + (menu?.bounds.height ?? 0),
      }),
    },
  });

  const onColumnResize = useCallback((column, newSize) => {
    setColSizes((prevColSizes) => {
      return {
        ...prevColSizes,
        [column.title]: newSize,
      };
    });
  }, []);

  const onHeaderMenuClick = useCallback((column, bounds) => {
    setMenu({ column, bounds });
  }, []);

  useEffect(() => {
    ctx.handleEvent("update_content", (content) => {
      setContent(content);
    });
  }, []);

  useEffect(() => {
    const icon = content.order === "asc" ? "arrowUp" : "arrowDown";
    const newColumns = columns.map((header) => ({
      ...header,
      overlayIcon: header.id === content.order_by ? icon : null,
    }));
    setColumns(newColumns);
  }, [content.order, content.order_by]);

  useEffect(() => {
    const newColumns = columns.map((header) => {
      return { ...header, width: colSizes[header.title] };
    });
    setColumns(newColumns);
  }, [colSizes]);

  useEffect(() => {
    const currentMenu = menu ? columns[menu.column].id : null;
    const themeOverride = { bgHeader: "#F0F5F9" };
    const newColumns = columns.map((header) => ({
      ...header,
      themeOverride: header.id === currentMenu ? themeOverride : null,
    }));
    setColumns(newColumns);
    setShowMenu(menu ? true : false);
  }, [menu]);

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
        {hasRefetch && (
          <RefetchButton onRefetch={() => ctx.pushEvent("refetch")} />
        )}
        <SearchButton toggleSearch={toggleSearch} />
        <LimitSelect
          limit={content.limit}
          totalRows={totalRows}
          onChange={(limit) => ctx.pushEvent("limit", { limit })}
        />
        {hasPagination && (
          <Pagination
            page={content.page}
            maxPage={content.max_page}
            onPrev={() =>
              ctx.pushEvent("show_page", { page: content.page - 1 })
            }
            onNext={() =>
              ctx.pushEvent("show_page", { page: content.page + 1 })
            }
          />
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
          headerHeight={headerHeight}
          drawHeader={drawHeader}
          verticalBorder={false}
          rowMarkers="both"
          onHeaderMenuClick={onHeaderMenuClick}
          showSearch={showSearch}
          getCellsForSelection={true}
          onSearchClose={toggleSearch}
          headerIcons={customHeaderIcons}
          overscrollX={100}
          isDraggable={false}
          smoothScrollX={true}
          smoothScrollY={true}
          onColumnResize={onColumnResize}
          columnSelect="none"
          gridSelection={selection}
          onGridSelectionChange={setSelection}
          rowMarkerStartIndex={rowMarkerStartIndex}
        />
      )}
      {showMenu &&
        renderLayer(
          <HeaderMenu
            layerProps={layerProps}
            orderBy={orderBy}
            selectAllCurrent={selectAllCurrent}
          />
        )}
      {!hasData && <p className="no-data">No data</p>}
      <div id="portal" />
    </div>
  );
}

function RefetchButton({ onRefetch }) {
  return (
    <button className="icon-button" aria-label="refresh" onClick={onRefetch}>
      <RiRefreshLine />
    </button>
  );
}

function SearchButton({ toggleSearch }) {
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

function LimitSelect({ limit, totalRows, onChange }) {
  return (
    <div>
      <form>
        <label className="input-label">Show</label>
        <select
          className="input"
          value={limit}
          onChange={(event) => onChange(parseInt(event.target.value))}
        >
          <option value="10">10</option>
          <option value="15">15</option>
          <option value="20">20</option>
          <option value={totalRows}>All</option>
        </select>
      </form>
    </div>
  );
}

function Pagination({ page, maxPage, onPrev, onNext }) {
  return (
    <div className="pagination">
      <button
        className="pagination__button"
        onClick={onPrev}
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
        onClick={onNext}
        disabled={page === maxPage}
      >
        <span>Next</span>
        <RiArrowRightSLine />
      </button>
    </div>
  );
}

function HeaderMenu({ layerProps, orderBy, selectAllCurrent }) {
  return (
    <div className="header-menu" {...layerProps}>
      <div className="header-menu-item" onClick={() => orderBy("asc")}>
        Sort: ascending
      </div>
      <div className="header-menu-item" onClick={() => orderBy("desc")}>
        Sort: descending
      </div>
      <div className="header-menu-item" onClick={() => orderBy(null)}>
        Sort: none
      </div>
      <div className="header-menu-item" onClick={selectAllCurrent}>
        Select: current page
      </div>
    </div>
  );
}
