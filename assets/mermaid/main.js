import mermaid from "mermaid";

mermaid.initialize({ startOnLoad: false });

export function init(ctx, content) {
  function render() {
    mermaid.render("graph1", content).then(({ svg, bindFunctions }) => {
      ctx.root.innerHTML = svg;

      if (bindFunctions) {
        bindFunctions(ctx.root);
      }

      // A workaround for https://github.com/mermaid-js/mermaid/issues/1758
      const svgEl = ctx.root.querySelector("svg");
      svgEl.removeAttribute("height");
    });
  }

  // If the JS view is not visible, defer initialization until it becomes visible
  if (window.innerWidth === 0) {
    window.addEventListener("resize", () => render(), { once: true });
  } else {
    render();
  }
}
