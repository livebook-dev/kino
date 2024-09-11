import React from "react";
import { RiSortAsc, RiSortDesc, RiAlignJustify } from "@remixicon/react";
import HeaderMenuItem from "./HeaderMenuItem";

export default function HeaderMenu({
  layerProps,
  selectAllCurrent,
  hasSorting,
  orderBy,
}) {
  return (
    <div
      className="flex w-48 flex-col rounded-b-md border border-gray-200 bg-white p-2 font-sans shadow-lg"
      {...layerProps}
    >
      <button
        className="mb-1.5 flex w-full justify-center rounded-lg border border-gray-200 bg-gray-100 px-3 py-1.5 text-sm font-medium leading-none text-gray-700 hover:bg-gray-200"
        onClick={selectAllCurrent}
      >
        Select this column
      </button>
      {hasSorting && (
        <>
          <HeaderMenuItem onClick={() => orderBy("asc")}>
            <RiSortAsc size={14} />
            <span>Sort: ascending</span>
          </HeaderMenuItem>
          <HeaderMenuItem onClick={() => orderBy("desc")}>
            <RiSortDesc size={14} />
            <span>Sort: descending</span>
          </HeaderMenuItem>
          <HeaderMenuItem onClick={() => orderBy("none")}>
            <RiAlignJustify size={14} />
            <span>Sort: none</span>
          </HeaderMenuItem>
        </>
      )}
    </div>
  );
}
