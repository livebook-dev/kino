import "https://cdn.jsdelivr.net/npm/mermaid@9.1.3/dist/mermaid.min.js";

mermaid.initialize({ startOnLoad: false });

export function init(ctx, content) {
  function render() {
    mermaid.render("graph1", content, (svgSource, bindListeners) => {
      ctx.root.innerHTML = svgSource;
      bindListeners && bindListeners(ctx.root);

      // A workaround for https://github.com/mermaid-js/mermaid/issues/1758
      const svg = ctx.root.querySelector("svg");
      svg.removeAttribute("height");
    });
  }

  // If the JS view is not visible, defer initialization until it becomes visible
  if (window.innerWidth === 0) {
    window.addEventListener("resize", () => render(), { once: true });
  } else {
    render();
  }
}
