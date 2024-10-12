import mermaid from "mermaid";
import "./main.css";

mermaid.initialize({ startOnLoad: false });

export function init(ctx, content) {
  ctx.importCSS("main.css")
  
  function render() {
    mermaid.render("graph1", content).then(({ svg, bindFunctions }) => {
      ctx.root.innerHTML = `
        <div id="mermaid">
          ${svg}
          <button id="download" title="Download">⇩</button>
        </div>
      `
      ctx.root.querySelector("#download").addEventListener("click", (event) => {
        var binaryData = [];
        binaryData.push(svg);
        const downloadBlob = URL.createObjectURL(new Blob(binaryData, {type: "image/svg+xml"}));

        const downloadLink = document.createElement("a");
        downloadLink.href = downloadBlob;
        downloadLink.download = "mermaid.svg";
        document.body.appendChild(downloadLink);

        downloadLink.dispatchEvent(
          new MouseEvent('click', { 
            bubbles: true, 
            cancelable: true, 
            view: window 
          })
        );

        document.body.removeChild(downloadLink);
      });

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
