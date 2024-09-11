import React from "react";
import { RiArrowLeftSLine, RiArrowRightSLine } from "@remixicon/react";

export default function Pagination({ page, maxPage, onPrev, onNext, rows }) {
  return (
    <div className="flex gap-3">
      <button
        className="flex items-center text-xs font-medium text-gray-500 hover:text-gray-800 focus:outline-none disabled:pointer-events-none disabled:text-gray-300"
        onClick={onPrev}
        disabled={page === 1}
      >
        <RiArrowLeftSLine size={16} />
        <span>Prev</span>
      </button>
      <div className="rounded-lg border border-gray-400 px-2 py-1 text-xs font-semibold text-gray-500">
        <span>
          {page} of {maxPage || "?"}
        </span>
      </div>
      <button
        className="flex items-center text-xs font-medium text-gray-500 hover:text-gray-800 focus:outline-none disabled:pointer-events-none disabled:text-gray-300"
        onClick={onNext}
        disabled={page === maxPage || rows === 0}
      >
        <span>Next</span>
        <RiArrowRightSLine size={16} />
      </button>
    </div>
  );
}
