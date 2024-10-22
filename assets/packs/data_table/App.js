import React, { useCallback, useEffect, useState } from "react";
import DataEditor, {
  GridCellKind,
  GridColumnIcon,
  CompactSelection,
  withAlpha,
  getMiddleCenterBias,
} from "@glideapps/glide-data-grid";
import { useLayer } from "react-laag";
import DataInfo from "./DataInfo";
import HeaderMenu from "./HeaderMenu";
import Pagination from "./Pagination";
import LimitSelect from "./LimitSelect";
import SearchButton from "./SearchButton";
import RefetchButton from "./RefetchButton";
import DownloadExported from "./DownloadExported";

const customHeaderIcons = {
  arrowUp: ({
    fgColor,
    bgColor,
  }) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20">
    <path fill="${fgColor}" d="M0 0h24v24H0z"/>
    <path fill="${bgColor}" d="M12 2c5.52 0 10 4.48 10 10s-4.48 10-10 10S2 17.52 2 12 6.48 2 12 2zm1 10h3l-4-4-4 4h3v4h2v-4z"/>
  </svg>`,
  arrowDown: ({
    fgColor,
    bgColor,
  }) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20">
    <path fill="${fgColor}" d="M0 0h24v24H0z"/>
    <path fill="${bgColor}" d="M12 2c5.52 0 10 4.48 10 10s-4.48 10-10 10S2 17.52 2 12 6.48 2 12 2zm1 10V8h-2v4H8l4 4 4-4h-3z"/>
  </svg>`,
  curlyBraces: ({
    bgColor,
  }) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="12" height="12" fill="white">
  <rect width="100%" height="100%" fill="${bgColor}" /> <path d="M4 18V14.3C4 13.4716 3.32843 12.8 2.5
  12.8H2V11.2H2.5C3.32843 11.2 4 10.5284 4 9.7V6C4 4.34315 5.34315 3 7 3H8V5H7C6.44772 5 6 5.44772 6
  6V10.1C6 10.9858 5.42408 11.7372 4.62623 12C5.42408 12.2628 6 13.0142 6 13.9V18C6 18.5523 6.44772 19 7
  19H8V21H7C5.34315 21 4 19.6569 4 18ZM20 14.3V18C20 19.6569 18.6569 21 17 21H16V19H17C17.5523 19 18 18.5523 18
  18V13.9C18 13.0142 18.5759 12.2628 19.3738 12C18.5759 11.7372 18 10.9858 18 10.1V6C18 5.44772 17.5523 5 17
  5H16V3H17C18.6569 3 20 4.34315 20 6V9.7C20 10.5284 20.6716 11.2 21.5 11.2H22V12.8H21.5C20.6716 12.8 20 13.4716 20
  14.3Z"></path></svg>`,
};

const headerIcons = {
  text: GridColumnIcon.HeaderString,
  number: GridColumnIcon.HeaderNumber,
  uri: GridColumnIcon.HeaderUri,
  date: GridColumnIcon.HeaderDate,
  list: GridColumnIcon.HeaderArray,
  struct: "curlyBraces",
};

const cellKind = {
  text: GridCellKind.Text,
  number: GridCellKind.Number,
  uri: GridCellKind.Uri,
  date: GridCellKind.Text,
  list: GridCellKind.Text,
  struct: GridCellKind.Text,
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

export function App({ ctx, data }) {
  const summariesItems = [];
  const columnsInitSize = [];

  const getColumnsData = (columns) => {
    const columnsData = columns.map((column) => {
      const summary = column.summary;
      const title = column.label;
      const id = column.key;
      columnsInitSize.push({ [title]: 250 });
      summary && summariesItems.push(summary.keys.length);
      return {
        title: title,
        id: id,
        type: column.type,
        icon: headerIcons[column.type] || GridColumnIcon.HeaderString,
        hasMenu: column.type !== "list",
        summary: summary,
      };
    });
    return columnsData;
  };

  const columnsInitData = getColumnsData(data.content.columns);
  const hasRefetch = data.features.includes("refetch");
  const hasExport = data.features.includes("export");
  const hasData = data.content.columns.length !== 0;
  const hasSummaries = summariesItems.length > 0;
  const hasSorting = data.features.includes("sorting");
  const hasRelocate = data.features.includes("relocate");
  const supportedFormats = hasExport ? data.export?.formats : null;
  const showDownload = hasExport && supportedFormats;

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

  const totalRows = content.total_rows;
  const hasEntries = hasData && totalRows > 0;

  const hasPagination =
    data.features.includes("pagination") &&
    (totalRows === null || totalRows > 0);

  const infiniteScroll = content.limit === totalRows;
  const headerTitleSize = 44;
  const headerItems =
    hasSummaries && hasEntries ? Math.max(...summariesItems) : 0;
  const headerHeight = headerTitleSize + headerItems * 22;
  const menuHeight = hasSorting ? 140 : 70;
  const fixedHeight = 440 + headerHeight;
  const minRowsToFitMenu = hasSorting ? 3 : 2;
  const autoHeight =
    totalRows && totalRows < minRowsToFitMenu && menu
      ? menuHeight + headerHeight
      : null;
  const height = totalRows >= 10 && infiniteScroll ? fixedHeight : autoHeight;
  const rowMarkerStartIndex = (content.page - 1) * content.limit + 1;
  const minColumnWidth = hasSummaries ? 150 : 50;
  const maxColumnWidth = 1200;
  const maxColumnAutoWidth = data.content.columns.length === 1 ? 800 : 350;
  const rows = content.page_length;

  const drawHeader = useCallback(
    (args, drawContent) => {
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
      const summary = content.columns[column.sourceIndex - 1].summary;
      const hasSummary = summary ? true : false;

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
        const formattedSummary = Object.fromEntries(
          summary.keys.map((k, i) => [k, summary.values[i]])
        );
        const fontSize = 13;
        const padding = fontSize + basePadding;
        const baseFont = `${fontSize}px ${theme.fontFamily}`;
        const titleFont = `bold ${baseFont}`;

        ctx.fillStyle = fillInfoStyle;
        Object.entries(formattedSummary).forEach(([key, value], index) => {
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
    },
    [content]
  );

  const getCellContent = useCallback(
    ([col, row]) => {
      const kind = cellKind[content.columns[col].type] || GridCellKind.Text;
      const columnar = content.data_orientation === "columns";
      const cellData = columnar
        ? content.data[col][row]
        : content.data[row][col];

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
    const key = order !== "none" ? menu.columnKey : null;
    ctx.pushEvent("order_by", { key, direction: order ?? "asc" });
    setMenu(null);
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
    setMenu(null);
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

  const onColumnMoved = useCallback((startIndex, endIndex) => {
    ctx.pushEvent("relocate", { from_index: startIndex, to_index: endIndex });
    setMenu(null);
    setSelection(emptySelection);
  }, []);

  const onHeaderMenuClick = useCallback(
    (column, bounds) => {
      const { summary, id, type } = columns[column];
      if (!summary) {
        setMenu({ column, bounds, columnKey: id, columnType: type });
      }
    },
    [columns]
  );

  const onHeaderClicked = useCallback(
    (column, { bounds }) => {
      const { id, type } = columns[column];
      setMenu({ column, bounds, columnKey: id, columnType: type });
    },
    [columns]
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

  useEffect(() => {
    selection.rows?.items.length > 0
      ? setRowMarkerOffset(1)
      : setRowMarkerOffset(0);
  }, [selection]);

  useEffect(() => {
    ctx.handleEvent("update_content", (content) => {
      const columnsData = getColumnsData(content.columns);
      setColumns(columnsData);
      setContent(content);
    });
    ctx.handleEvent("download_content", ([info, arrayBuffer]) => {
      const blob = new Blob([arrayBuffer], { type: info.type });
      const link = document.createElement("a");
      link.href = window.URL.createObjectURL(blob);
      link.download = `${info.filename}-${+new Date()}${info.format}`;
      link.click();
    });
  }, []);

  useEffect(() => {
    const icon = content.order?.direction === "asc" ? "arrowUp" : "arrowDown";
    const newColumns = columns.map((header) => ({
      ...header,
      overlayIcon: header.id === content.order?.key ? icon : null,
    }));
    setColumns(newColumns);
  }, [content.order?.direction, content.order?.key]);

  useEffect(() => {
    const newColumns = columns.map((header) => {
      return { ...header, width: colSizes[header.title] };
    });
    setColumns(newColumns);
  }, [colSizes]);

  useEffect(() => {
    const currentMenu = menu?.columnKey;
    const themeOverride = { bgHeader: "#F0F5F9" };
    const newColumns = columns.map((header) => ({
      ...header,
      themeOverride: header.id === currentMenu ? themeOverride : null,
    }));
    setColumns(newColumns);
    setShowMenu(menu ? true : false);
  }, [menu]);

  return (
    <div className="p-3 font-sans">
      <div className="mb-6 flex items-center gap-3">
        <DataInfo data={data} totalRows={totalRows} />
        {showDownload && (
          <DownloadExported
            supportedFormats={supportedFormats}
            onDownload={(format) => ctx.pushEvent("download", { format })}
          />
        )}
        <div className="grow"></div>
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
            rows={rows}
          />
        )}
      </div>
      {hasData && (
        <DataEditor
          className="max-w-full rounded-lg shadow-[0_2px_10px_rgb(0,0,0,0.15)]"
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
          onGridSelectionChange={(selection) => setSelection(selection)}
          rowMarkerStartIndex={rowMarkerStartIndex}
          minColumnWidth={minColumnWidth}
          maxColumnWidth={maxColumnWidth}
          maxColumnAutoWidth={maxColumnAutoWidth}
          fillHandle={true}
          onItemHovered={onItemHovered}
          getRowThemeOverride={getRowThemeOverride}
          onColumnMoved={hasRelocate ? onColumnMoved : undefined}
        />
      )}
      {showMenu &&
        renderLayer(
          <HeaderMenu
            layerProps={layerProps}
            menu={menu}
            orderBy={orderBy}
            selectAllCurrent={selectAllCurrent}
            hasSorting={hasSorting}
          />
        )}
      {!hasData && <p className="text-sm text-gray-700">No data</p>}
      <div id="portal" />
    </div>
  );
}
