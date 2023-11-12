import React, { useEffect, useState } from "react";

export default function App({ ctx, payload }) {
  const { dbg_same_file: dbgSameFile, dbg_line: dbgLine, source } = payload;

  const [callCount, setCallCount] = useState(payload.call_count);

  useEffect(() => {
    ctx.handleEvent("call_count_updated", ({ call_count }) => {
      setCallCount(call_count);
    });
  }, []);

  return (
    <div class="app">
      <div class="headline">
        <span class="dbg">dbg:{dbgLine}</span>
        <span>{formatDbgInfo(dbgSameFile, callCount)}</span>
      </div>
      <div class="source">{source}</div>
    </div>
  );
}

function formatDbgInfo(dbgSameFile, callCount) {
  const info = [
    !dbgSameFile && "from another cell",
    callCount > 1 && `showing first out of ${callCount} calls`,
  ]
    .filter((x) => x)
    .join("; ");

  if (info) {
    return `(${info})`;
  } else {
    return null;
  }
}
