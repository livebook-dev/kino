import React, { useRef } from "react";
import { RiFileDownloadLine } from "@remixicon/react";
import IconButton from "./IconButton";

export default function DownloadExported({ supportedFormats, onDownload }) {
  const selectRef = useRef();

  return (
    <span className="tooltip right" data-tooltip="Export to">
      <IconButton onClick={(_event) => selectRef.current.click()}>
        <div className="relative">
          <RiFileDownloadLine size={18} />
          <select
            className="absolute inset-0 cursor-pointer opacity-0"
            ref={selectRef}
            value=""
            onChange={(event) => onDownload(event.target.value)}
          >
            <option disabled value="">
              Export to
            </option>
            {supportedFormats.map((format) => (
              <option key={format}>{format}</option>
            ))}
          </select>
        </div>
      </IconButton>
    </span>
  );
}
