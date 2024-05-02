import React from "react";
import { RiSearch2Line } from "@remixicon/react";
import IconButton from "./IconButton";

export default function SearchButton({ toggleSearch }) {
  return (
    <span className="tooltip right" data-tooltip="Current page search">
      <IconButton aria-label="search" onClick={toggleSearch}>
        <RiSearch2Line size={16} />
      </IconButton>
    </span>
  );
}
