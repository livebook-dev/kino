import React from "react";

export default function ActionMenu({ layerProps, actions, onClick }) {
  return (
    <div
      className="flex w-content max-w-48 flex-col rounded-md border border-gray-200 bg-white p-2 font-sans shadow-lg"
      {...layerProps}
    >
      {actions.map(({ label, tag }, index) => (
        <div
          key={index}
          className="flex cursor-pointer items-center justify-start gap-1 p-1 text-sm text-gray-700 hover:bg-gray-100"
          onClick={(_) => onClick({ action: tag })}
        >
          {label}
        </div>
      ))}
    </div>
  );
}
