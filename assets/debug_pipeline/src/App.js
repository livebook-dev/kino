import React, { useCallback, useEffect, useMemo, useState } from "react";
import classNames from "classnames";
import { arrayMove } from "@dnd-kit/sortable";
import { RiClipboardLine } from "@remixicon/react";

import SortableList from "./SortableList";
import SortableListItem from "./SortableListItem";
import Switch from "./Switch";
import IconButton from "./IconButton";

export default function App({ ctx, payload }) {
  const { dbg_same_file: dbgSameFile, dbg_line: dbgLine } = payload;

  const [callCount, setCallCount] = useState(payload.call_count);
  const [items, setItems] = useState(payload.items);
  const [selectedId, setSelectedId] = useState(payload.selected_id);
  const [erroredId, setErroredId] = useState(payload.errored_id);
  const [error, setError] = useState(payload.error);
  const [isChanged, setIsChanged] = useState(payload.changed);

  const abortedIds = useMemo(() => {
    if (erroredId === null) {
      return [];
    } else {
      const erroredIdx = items.findIndex((item) => item.id === erroredId);
      return items.slice(erroredIdx).map((item) => item.id);
    }
  }, [items, erroredId]);

  const isItemSelectable = useCallback(
    (item) => {
      return item.enabled && !abortedIds.includes(item.id);
    },
    [abortedIds],
  );

  const moveSelection = useCallback(
    (offset) => {
      const selectableItems = items.filter(isItemSelectable);
      const idx = selectableItems.findIndex((item) => item.id === selectedId);
      const item = selectableItems[idx + offset];

      if (item) {
        ctx.pushEvent("select_item", { id: item.id });
      }
    },
    [items, selectedId, isItemSelectable],
  );

  useEffect(() => {
    const listener = (event) => {
      if (event.key === "ArrowUp") {
        moveSelection(-1);
        event.preventDefault();
      } else if (event.key === "ArrowDown") {
        moveSelection(1);
        event.preventDefault();
      }
    };

    window.addEventListener("keydown", listener);
    return () => window.removeEventListener("keydown", listener);
  }, [moveSelection]);

  useEffect(() => {
    ctx.handleEvent("item_selected", ({ id }) => {
      setSelectedId(id);
    });

    ctx.handleEvent("set_errored", ({ id, error, selected_id }) => {
      setErroredId(id);
      setError(error);
      setSelectedId(selected_id);
    });

    ctx.handleEvent(
      "enabled_updated",
      ({ id, enabled, selected_id, changed }) => {
        setItems((items) =>
          items.map((item) => (item.id === id ? { ...item, enabled } : item)),
        );
        setSelectedId(selected_id);
        setIsChanged(changed);
      },
    );

    ctx.handleEvent("item_moved", ({ id, index, changed }) => {
      setItems((items) => {
        const currentIndex = items.findIndex((item) => item.id === id);
        return arrayMove(items, currentIndex, index);
      });

      setIsChanged(changed);
    });

    ctx.handleEvent("call_count_updated", ({ call_count }) => {
      setCallCount(call_count);
    });
  }, []);

  function copySource() {
    const source = items
      .filter((item) => item.enabled)
      .map((item) => item.source)
      .join("\n");

    copyToClipboard(source);
  }

  function handleItemClick(item) {
    if (isItemSelectable(item)) {
      ctx.pushEvent("select_item", { id: item.id });
    }
  }

  function handleItemDrop(fromId, toId) {
    const fromIndex = items.findIndex((item) => item.id === fromId);

    const toIndex = Math.max(
      items.findIndex((item) => item.id === toId),
      1,
    );

    if (fromIndex === toIndex) return;

    const item = items[fromIndex];
    ctx.pushEvent("move_item", { id: item.id, index: toIndex });

    // Optimistic UI update to make a smooth animation
    setItems((items) => arrayMove(items, fromIndex, toIndex));
  }

  function handleEnabledChange(item, event) {
    ctx.pushEvent("update_enabled", {
      id: item.id,
      enabled: event.target.checked,
    });
  }

  return (
    <div className="font-mono text-gray-700">
      <div className="mb-2 flex items-center justify-between">
        <div className="flex items-center text-xs">
          <span className="mr-2 rounded bg-gray-300 px-1 py-0.5">
            dbg:{dbgLine}
          </span>
          <span>{formatDbgInfo(dbgSameFile, callCount)}</span>
        </div>
        <div>
          <div
            className="flex cursor-pointer items-center hover:text-gray-900"
            onClick={copySource}
          >
            {isChanged && (
              <span className="mr-1 flex items-center text-xs">
                <span className="bg-yellow-bright-200 relative mr-2 inline-flex h-3 w-3 rounded-full"></span>
                <span>Copy new pipeline</span>
              </span>
            )}
            <IconButton>
              <RiClipboardLine size={20} />
            </IconButton>
          </div>
        </div>
      </div>
      <SortableList
        items={items}
        onDrop={handleItemDrop}
        render={(item, index) => (
          <SortableListItem key={item.id} id={item.id} disabled={index === 0}>
            <div
              className={classNames([
                "flex flex-col bg-white py-2 text-sm",
                index > 0 && "border-t border-gray-200",
                isItemSelectable(item)
                  ? "cursor-pointer"
                  : "cursor-default text-gray-400",
                item.id === selectedId && "text-blue-600",
                item.id === erroredId && "text-red-600",
              ])}
              onClick={() => handleItemClick(item)}
            >
              <div className="flex min-h-[28px] items-center justify-between">
                <span className="whitespace-pre-wrap">{item.source}</span>
                {index !== 0 && (
                  <Switch
                    checked={item.enabled}
                    onChange={(event) => handleEnabledChange(item, event)}
                  />
                )}
              </div>
              {item.id === erroredId && (
                <div className="mt-4 whitespace-pre-wrap">{error}</div>
              )}
            </div>
          </SortableListItem>
        )}
      />
      <div className="mt-4 text-xs">Output:</div>
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

function copyToClipboard(text) {
  if ("clipboard" in navigator) {
    navigator.clipboard.writeText(text);
  } else {
    alert(
      "Sorry, your browser does not support clipboard copy.\nThis generally requires a secure origin - either HTTPS or localhost.",
    );
  }
}
