import React, { useState } from "react";
import { RiArrowDownSFill, RiArrowRightSFill } from "@remixicon/react";
import classNames from "classnames";

const MAX_AUTO_EXPAND_SIZE = 6;

function shouldAutoExpand(node, level) {
  return (
    level === 1 ||
    (node.kind === "tuple" && node.children?.length <= MAX_AUTO_EXPAND_SIZE)
  );
}

export default function App({ tree }) {
  return (
    <div className="font-mono text-sm text-gray-500">
      <TreeNode node={tree} level={1} />
    </div>
  );
}

function TreeNode({ node, level }) {
  const [isExpanded, setIsExpanded] = useState(shouldAutoExpand(node, level));

  function handleExpandClick() {
    if (node.children) {
      setIsExpanded(!isExpanded);
    }
  }

  return (
    <>
      <div
        className={classNames(["flex", node.children && "cursor-pointer"])}
        onClick={handleExpandClick}
      >
        <div className="mr-0.5 inline-block w-[2ch] flex-shrink-0">
          {node.children &&
            (isExpanded ? (
              <RiArrowDownSFill size={20} />
            ) : (
              <RiArrowRightSFill size={20} />
            ))}
        </div>
        <div>
          {node.children && isExpanded ? (
            <TextItems items={node.expanded.prefix} />
          ) : (
            <TextItems items={node.content} />
          )}
        </div>
      </div>
      {node.children && isExpanded && (
        <>
          <ol className="m-0 ml-[2ch] block list-none p-0">
            {node.children.map((child, index) => (
              <li className="flex flex-col">
                <TreeNode node={child} level={level + 1} />
              </li>
            ))}
          </ol>
          <div className="ml-[2ch]">
            <TextItems items={node.expanded.suffix} />
          </div>
        </>
      )}
    </>
  );
}

function TextItems({ items }) {
  return items.map((item, index) => (
    <span
      key={index}
      className="whitespace-pre"
      style={item.color ? { color: item.color } : {}}
    >
      {item.text}
    </span>
  ));
}
