import React from "react";

export default function DataInfo({ data, totalRows }) {
  return (
    <div className="flex items-baseline">
      <h2 className="text-md font-semibold leading-none text-gray-800">
        {data.name}
      </h2>
      <span className="ml-2.5 text-xs leading-none">
        {totalRows || "?"} {totalRows === 1 ? "entry" : "entries"}
      </span>
      {totalRows < data.content.total_rows}
    </div>
  );
}
