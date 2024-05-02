import React from "react";
import { RiRefreshLine } from "@remixicon/react";
import IconButton from "./IconButton";

export default function RefetchButton({ onRefetch }) {
  return (
    <IconButton aria-label="refresh" onClick={onRefetch}>
      <RiRefreshLine />
    </IconButton>
  );
}
