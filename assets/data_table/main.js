import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
  CompactSelection,
  withAlpha,
  getMiddleCenterBias,
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

const filtering = {
  numeric: ["less", "less_eq", "equal", "not_equal", "greater_eq", "greater"],
  categorical: ["equal", "not_equal"],
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
  const summariesItems = [];
  const columnsInitSize = [];

  const columnsInitData = data.content.columns.map((column) => {
    const summary = column.summary;
    const title = column.label;
    columnsInitSize.push({ [title]: 250 });
    summary && summariesItems.push(Object.keys(summary).length);
    return {
      title: title,
      id: column.key,
      icon: headerIcons[column.type] || GridColumnIcon.HeaderString,
      hasMenu: true,
      summary: summary,
    };
  });

  const hasRefetch = data.features.includes("refetch");
  const hasData = data.content.columns.length !== 0;
  const hasSummaries = summariesItems.length > 0;
  const hasFiltering = data.features.includes("filtering");

  const emptySelection = {
    rows: CompactSelection.empty(),
    columns: CompactSelection.empty(),
  };

  const [content, setContent] = useState(data.content);
  const [showSearch, setShowSearch] = useState(false);
  const [columns, setColumns] = useState(columnsInitData);
  const [colSizes, setColSizes] = useState(columnsInitSize);
  const [menu, setMenu] = useState(null);
  const [showMenu, setShowMenu] = useState(false);
  const [selection, setSelection] = useState(emptySelection);
  const [rowMarkerOffset, setRowMarkerOffset] = useState(0);
  const [hoverRows, setHoverRows] = useState(null);
  const [filter, setFilter] = useState({
    filter: data.content.filter,
    filterValue: null,
  });

  const totalRows = content.total_rows;
  const hasEntries = hasData && totalRows > 0;

  const hasPagination =
    data.features.includes("pagination") &&
    (totalRows === null || totalRows > 0);

  const infiniteScroll = content.limit === totalRows;
  const headerTitleSize = 44;
  const headerItems = hasSummaries ? Math.max(...summariesItems) : 0;
  const headerHeight = headerTitleSize + headerItems * 22;
  const menuHeight = hasFiltering ? 185 : 70;
  const fixedHeight = 440 + headerHeight;
  const autoHeight = totalRows < 5 && menu ? menuHeight + headerHeight : null;
  const height = totalRows >= 10 && infiniteScroll ? fixedHeight : autoHeight;
  const rowMarkerStartIndex = (content.page - 1) * content.limit + 1;
  const minColumnWidth = hasSummaries ? 150 : 50;
  const rows = content.page_length;

  const drawHeader = useCallback(
    (args) => {
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

      const basePadding = 10;
      const overlayIconSize = 19;

      const fillStyle = isSelected
        ? theme.textHeaderSelected
        : theme.textHeader;
      const fillInfoStyle = isSelected ? theme.accentLight : theme.textDark;
      const shouldDrawMenu = column.hasMenu === true && isHovered;
      const hasSummary = column.summary ? true : false;

      const fadeWidth = 35;
      const fadeStart = rect.width - fadeWidth;
      const fadeEnd = rect.width - fadeWidth * 0.7;

      const fadeStartPercent = fadeStart / rect.width;
      const fadeEndPercent = fadeEnd / rect.width;

      const grad = ctx.createLinearGradient(rect.x, 0, rect.x + rect.width, 0);
      const trans = withAlpha(fillStyle, 0);

      const middleCenter = getMiddleCenterBias(
        ctx,
        `${theme.headerFontStyle} ${theme.fontFamily}`
      );

      grad.addColorStop(0, fillStyle);
      grad.addColorStop(fadeStartPercent, fillStyle);
      grad.addColorStop(fadeEndPercent, trans);
      grad.addColorStop(1, trans);

      ctx.fillStyle = shouldDrawMenu ? grad : fillStyle;

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
          rect.x + basePadding,
          rect.y + basePadding,
          headerSize,
          theme
        );

        if (column.overlayIcon) {
          spriteManager.drawSprite(
            column.overlayIcon,
            isSelected ? "selected" : "special",
            ctx,
            rect.x + basePadding + overlayIconSize / 2,
            rect.y + basePadding + overlayIconSize / 2,
            overlayIconSize,
            theme
          );
        }
      }

      ctx.fillText(
        column.title,
        menuBounds.x - rect.width + theme.headerIconSize * 2.5 + 14,
        hasSummary
          ? rect.y + basePadding + theme.headerIconSize / 2 + middleCenter
          : menuBounds.y + menuBounds.height / 2 + middleCenter
      );

      if (hasSummary) {
        const summary = content.columns[column.sourceIndex - 1].summary;
        const fontSize = 13;
        const padding = fontSize + basePadding;
        const baseFont = `${fontSize}px ${theme.fontFamily}`;
        const titleFont = `bold ${baseFont}`;

        ctx.fillStyle = fillInfoStyle;
        Object.entries(summary).forEach(([key, value], index) => {
          ctx.font = titleFont;
          ctx.fillText(
            `${key}:`,
            rect.x + padding / 2,
            rect.y + padding * (index + 1) + padding
          );
          ctx.font = baseFont;
          ctx.fillText(
            value,
            rect.x + ctx.measureText(key).width + padding,
            rect.y + padding * (index + 1) + padding
          );
        });
      }

      if (shouldDrawMenu) {
        ctx.fillStyle = grad;
        const arrowX = menuBounds.x + menuBounds.width / 2 - basePadding * 1.5;
        const arrowY = theme.headerIconSize / 2 - 2;
        const p = new Path2D("M12 16l-6-6h12z");
        ctx.translate(arrowX, arrowY);
        ctx.fill(p);
      }

      return true;
    },
    [content]
  );

  const getCellContent = useCallback(
    ([col, row]) => {
      const cellData = content.rows[row]?.fields[col] || "";
      const kind = cellKind[content.columns[col].type] || GridCellKind.Text;

      return {
        kind: kind,
        data: cellData,
        displayData: cellData,
        allowOverlay: true,
        allowWrapping: false,
        readonly: true,
      };
    },
    [content]
  );

  const toggleSearch = () => {
    setShowSearch(!showSearch);
  };

  const orderBy = (order) => {
    const key = order !== "none" ? columns[menu.column].id : null;
    ctx.pushEvent("order_by", { key, order: order ?? "asc" });
  };

  const filterBy = (filter, value) => {
    const key = filter ? columns[menu.column].id : null;
    const filterMessage = `(${columns[menu.column].title} ${filter} ${value})`;
    setFilter({ filter: "equal", filterValue: null, filterMessage });
    ctx.pushEvent("filter_by", { key, filter: filter ?? "equal", value });
  };

  const onPrev = () => {
    ctx.pushEvent("show_page", { page: content.page - 1 });
    setSelection({ ...emptySelection, columns: selection.columns });
  };

  const onNext = () => {
    ctx.pushEvent("show_page", { page: content.page + 1 });
    setSelection({ ...emptySelection, columns: selection.columns });
  };

  const selectAllCurrent = () => {
    const newSelection = {
      ...emptySelection,
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
    if (!columns[column].summary) {
      setMenu({ column, bounds });
    }
  }, []);

  const onHeaderClicked = useCallback(
    (column, { localEventX, localEventY, bounds }) => {
      if (localEventX >= bounds.width - 50 && localEventY <= 25) {
        setMenu({ column, bounds });
      }
    },
    []
  );

  const onItemHovered = useCallback(
    (args) => {
      const [col, row] = args.location;
      if (row === -1 && col === -1 && args.kind === "header") {
        setHoverRows([...Array.from({ length: rows }, (_, index) => index)]);
      } else if (col === -1 && args.kind === "cell") {
        setHoverRows([row]);
      } else {
        setHoverRows(null);
      }
    },
    [rows]
  );

  const getRowThemeOverride = useCallback(
    (row) =>
      hoverRows?.includes(row) ? { bgCell: theme.bgHeaderHovered } : null,
    [hoverRows]
  );

  const getCellsForSelection = useCallback(
    ({ x, y, width, height }) => {
      const selected = [];
      const max = content.columns.length;
      const offSet = width >= max ? 0 : x + width >= max ? 0 : rowMarkerOffset;
      const rows = [...Array.from({ length: height }, (_, index) => index + y)];
      const cols = [
        ...Array.from({ length: width + offSet }, (_, index) => index + x),
      ];
      rows.forEach((i) => {
        const row = [];
        cols.forEach((j) => {
          row.push(getCellContent([j, i]));
        });
        selected.push(row);
      });
      return selected;
    },
    [rowMarkerOffset, getCellContent]
  );

  useEffect(() => {
    selection.rows?.items.length > 0
      ? setRowMarkerOffset(1)
      : setRowMarkerOffset(0);
  }, [selection]);

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
            {totalRows || "?"} {totalRows > 1 ? "entries" : "entry"}
          </span>
          {totalRows < data.content.total_rows && (
            <span className="navigation__details">
              {filter.filterMessage} of {data.content.total_rows}
            </span>
          )}
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
            onPrev={onPrev}
            onNext={onNext}
          />
        )}
      </div>
      {hasEntries && (
        <DataEditor
          className="table-container"
          theme={theme}
          getCellContent={getCellContent}
          columns={columns}
          rows={rows}
          width="100%"
          height={height}
          rowHeight={44}
          headerHeight={headerHeight}
          drawHeader={drawHeader}
          verticalBorder={false}
          rowMarkers="clickable-number"
          rowMarkerWidth={32}
          onHeaderMenuClick={onHeaderMenuClick}
          onHeaderClicked={onHeaderClicked}
          showSearch={showSearch}
          getCellsForSelection={getCellsForSelection}
          onSearchClose={toggleSearch}
          headerIcons={customHeaderIcons}
          overscrollX={100}
          isDraggable={false}
          smoothScrollX={true}
          smoothScrollY={true}
          onColumnResize={onColumnResize}
          columnSelect="none"
          gridSelection={selection}
          onGridSelectionChange={(selection) => setSelection(selection)}
          rowMarkerStartIndex={rowMarkerStartIndex}
          minColumnWidth={minColumnWidth}
          maxColumnAutoWidth={300}
          fillHandle={true}
          onItemHovered={onItemHovered}
          getRowThemeOverride={getRowThemeOverride}
        />
      )}
      {showMenu &&
        renderLayer(
          <HeaderMenu
            layerProps={layerProps}
            columnType={content.columns[menu?.column]?.type}
            orderBy={orderBy}
            selectAllCurrent={selectAllCurrent}
            hasFiltering={hasFiltering}
            filterBy={filterBy}
            filter={filter}
            setFilter={setFilter}
          />
        )}
      {!hasData && <p className="no-data">No data</p>}
      {hasData && !hasEntries && (
        <div>
          <p className="no-data">No entries found</p>
          <button className="menu__button" onClick={() => filterBy(null, null)}>
            <span>Reset filters</span>
          </button>
        </div>
      )}
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

function HeaderMenu({ layerProps, selectAllCurrent, orderBy, ...props }) {
  return (
    <div className="header-menu" {...layerProps}>
      <div className="header-menu-item button" onClick={selectAllCurrent}>
        Select: current page
      </div>
      <form>
        <label className="header-menu-item input-label">Sort: </label>
        <select
          className="header-menu-input input"
          onClick={(event) => orderBy(event.target.value)}
        >
          <option value="none">none</option>
          <option value="asc">ascending</option>
          <option value="desc">descending</option>
        </select>
      </form>
      {props.hasFiltering && (
        <Filtering
          columnType={props.columnType}
          filterBy={props.filterBy}
          filter={props.filter}
          setFilter={props.setFilter}
        />
      )}
    </div>
  );
}

function Filtering({ columnType, filterBy, filter, setFilter }) {
  const toOption = (option) => <option value={option}>{option}</option>;
  const numericOptions = filtering.numeric.map((option) => toOption(option));
  const categoricalOptions = filtering.categorical.map((option) =>
    toOption(option)
  );
  const isNumber = columnType === "number";
  const validFilter = filter.filterValue || filter.filterValue === 0;
  return (
    <div>
      <label className="header-menu-item input-label">Filter: </label>
      <div className="header-menu-item-wrapper">
        <form>
          <select
            className="header-menu-input input"
            onChange={(event) =>
              setFilter({ ...filter, filter: event.target.value })
            }
            value={filter.filter}
          >
            {isNumber ? numericOptions : categoricalOptions}
          </select>
          <input
            type="text"
            className="header-menu-input input input-text"
            onChange={(event) =>
              setFilter({
                ...filter,
                filterValue: isNumber
                  ? event.target.value.replace(/[^\d.,-]/g, "")
                  : event.target.value,
              })
            }
            value={validFilter ? filter.filterValue : ""}
          ></input>
        </form>
        <div className="inline-buttons">
          <button
            className="menu__button"
            onClick={() =>
              filterBy(
                filter.filter,
                isNumber ? parseFloat(filter.filterValue) : filter.filterValue
              )
            }
            disabled={!validFilter}
          >
            <span>Filter</span>
          </button>
          <button className="menu__button" onClick={() => filterBy(null, null)}>
            <span>Reset</span>
          </button>
        </div>
      </div>
    </div>
  );
}
