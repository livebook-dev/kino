import React from "react";
import { RiArrowDownSLine } from "@remixicon/react";

export default function LimitSelect({ limit, totalRows, onChange }) {
  return (
    <div>
      <form>
        <label className="p-1 text-xs font-medium text-gray-500">Show</label>
        <div class="relative inline-block">
          <select
            className="appearance-none rounded-lg border border-gray-400 bg-white px-2 py-1 pr-7 text-xs font-medium text-gray-500 focus:outline-none"
            value={limit}
            onChange={(event) => onChange(parseInt(event.target.value))}
          >
            <option value="10">10</option>
            <option value="20">20</option>
            <option value="50">50</option>
            <option value="100">100</option>
            {totalRows ? <option value={totalRows}>All</option> : null}
          </select>
          <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500">
            <RiArrowDownSLine size={16} />
          </div>
        </div>
      </form>
    </div>
  );
}
