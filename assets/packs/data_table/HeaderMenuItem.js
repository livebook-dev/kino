import React from "react";

export default function HeaderMenuItem({ children, ...props }) {
  return (
    <div
      {...props}
      className="flex cursor-pointer items-center justify-start gap-1 p-1 text-sm text-gray-700 hover:bg-gray-100"
    >
      {children}
    </div>
  );
}
