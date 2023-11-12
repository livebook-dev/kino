import React, { useState } from "react";
import { createRoot } from "react-dom/client";

import "./main.css";

export function init(ctx, tree) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css"
  );

  const root = createRoot(ctx.root);
  root.render(<App tree={tree} />);
}

function App({ tree }) {
  return (
    <div className="app">
      <div className="tree">
        <TreeNode node={tree} level={1} />
      </div>
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
        className={`item ${node.children ? "clickable" : ""}`}
        onClick={handleExpandClick}
      >
        <div className="icon-container">
          {node.children && (
            <i
              className={`ri ${
                expanded ? "ri-arrow-down-s-fill" : "ri-arrow-right-s-fill"
              }`}
            />
          )}
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
          <ol>
            {node.children.map((child, index) => (
              <li>
                <TreeNode node={child} level={level + 1} />
              </li>
            ))}
          </ol>
          <div className="suffix">
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
      className="code"
      style={item.color ? { color: item.color } : {}}
    >
      {item.text}
    </span>
  ));
}
