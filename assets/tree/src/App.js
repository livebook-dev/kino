import React, { useState } from "react";
import { RiArrowDownSFill, RiArrowRightSFill } from "@remixicon/react";
import classNames from "classnames";

export default function App({ tree }) {
  return (
    <div className="font-mono text-sm text-gray-500">
      <TreeNode node={tree} level={1} />
    </div>
  );
}

function TreeNode({ node, level }) {
  const [expanded, setExpanded] = useState(level === 1);

  function handleExpandClick() {
    if (node.children) {
      setExpanded(!expanded);
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
            (expanded ? (
              <RiArrowDownSFill size={20} />
            ) : (
              <RiArrowRightSFill size={20} />
            ))}
        </div>
        <div>
          {node.children && expanded ? (
            <TextItems items={node.expanded.prefix} />
          ) : (
            <TextItems items={node.content} />
          )}
        </div>
      </div>
      {node.children && expanded && (
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
