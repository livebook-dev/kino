import React from "react";

export default function Switch(props) {
  return (
    <label className="relative inline-block h-7 w-14 select-none">
      <input
        type="checkbox"
        className="peer absolute block h-7 w-7 cursor-pointer appearance-none rounded-full border-[5px] border-gray-100 bg-gray-400 outline-none transition-all duration-300 checked:translate-x-full checked:transform checked:border-blue-600 checked:bg-white"
        {...props}
      />
      <div className="block h-full w-full cursor-pointer rounded-full bg-gray-100 transition-all duration-300 peer-checked:bg-blue-600" />
    </label>
  );
}
