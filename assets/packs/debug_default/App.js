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
    <div class="font-mono">
      <div class="mb-4 flex items-center text-xs">
        <span class="mr-2 rounded bg-gray-300 px-1 py-0.5">dbg:{dbgLine}</span>
        <span>{formatDbgInfo(dbgSameFile, callCount)}</span>
      </div>
      <div class="whitespace-pre-wrap text-xs">{source}</div>
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
