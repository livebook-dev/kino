import React from "react";
import { RiArrowDownSLine } from "@remixicon/react";

const LIMIT_OPTIONS = [10, 20, 50, 100];

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
            {!LIMIT_OPTIONS.includes(limit) && (
              <option key={limit} value={limit.toString()}>
                {limit}
              </option>
            )}
            {LIMIT_OPTIONS.map((value) => (
              <option key={value} value={value.toString()}>
                {value}
              </option>
            ))}
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
