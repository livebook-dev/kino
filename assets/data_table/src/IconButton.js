import React from "react";

export default function IconButton({ children, ...props }) {
  return (
    <button
      {...props}
      className="align-center flex cursor-pointer items-center rounded-full p-1 leading-none text-gray-500 hover:text-gray-900 focus:bg-gray-100 focus:outline-none disabled:cursor-default disabled:text-gray-300"
    >
      {children}
    </button>
  );
}
