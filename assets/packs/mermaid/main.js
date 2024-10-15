import mermaid from "mermaid";
import "./main.css";

mermaid.initialize({ startOnLoad: false });

export function init(ctx, { diagram, caption, download }) {
  ctx.importCSS("main.css");

  function render() {
    mermaid.render("diagram", diagram).then(({ svg, bindFunctions }) => {
      // Fix for: https://github.com/mermaid-js/mermaid/issues/1766
      svg = svg.replace(/<br>/gi, "<br/>");

      let container = document.createElement("div");
      container.classList.add("container");
      ctx.root.appendChild(container);

      const figure = document.createElement("figure");
      figure.classList.add("figure");
      figure.innerHTML = svg;
      // The diagram intrinsic width is actually in max-width, so we adjust it
      figure.firstElementChild.style.width =
        figure.firstElementChild.style.maxWidth;
      figure.firstElementChild.style.maxWidth = "100%";
      container.appendChild(figure);

      if (caption) {
        const figcaption = document.createElement("figcaption");
        figcaption.classList.add("caption");
        figcaption.textContent = caption;
        figure.appendChild(figcaption);
      }

      if (download) {
        const downloadBtn = document.createElement("button");
        downloadBtn.classList.add("download-btn");
        downloadBtn.title = "Download";
        downloadBtn.innerHTML = `<svg width="20" height="20" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M13 10H18L12 16L6 10H11V3H13V10ZM4 19H20V12H22V20C22 20.5523 21.5523 21 21 21H3C2.44772 21 2 20.5523 2 20V12H4V19Z"></path></svg>`;
        figure.appendChild(downloadBtn);

        downloadBtn.addEventListener("click", (event) => {
          const blobURL = URL.createObjectURL(
            new Blob([svg], { type: "image/svg+xml" }),
          );

          const a = document.createElement("a");
          a.style.display = "none";
          a.href = blobURL;
          a.download = "diagram.svg";

          container.appendChild(a);
          a.click();
          container.removeChild(a);
        });
      }

      if (bindFunctions) {
        bindFunctions(ctx.root);
      }

      // A workaround for https://github.com/mermaid-js/mermaid/issues/1758
      const svgEl = figure.querySelector("svg");
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
