import mermaid from "mermaid";
import "./main.css";

mermaid.initialize({ startOnLoad: false });

export function init(ctx, {diagram, caption, download}) {
  ctx.importCSS("main.css")
  
  function render() {
    mermaid.render("diagram", diagram).then(({ svg, bindFunctions }) => {
      // Fix for: https://github.com/mermaid-js/mermaid/issues/1766
      const renderedSvg = svg.replace(/<br>/gi, "<br />")
      
      let contents = document.createElement("div");
      contents.id = "contents";
      ctx.root.appendChild(contents);
      
      let figure = document.createElement("figure");
      figure.id = "figure";
      figure.innerHTML = renderedSvg;
      contents.appendChild(figure);
      
      if (caption) {
        let figcaption = document.createElement("figcaption");
        figcaption.textContent = caption;
        figure.appendChild(figcaption);
      }
      
      if (download) {
        let downloadButton = document.createElement("button");
        downloadButton.id = "download"
        downloadButton.title = `Download ${download.title}`
        downloadButton.textContent = "⇩"
        contents.prepend(downloadButton);
      
        contents.querySelector("#download").addEventListener("click", (event) => {
          var downloadData = [];
          downloadData.push(renderedSvg);
          const downloadBlob = URL.createObjectURL(new Blob(downloadData, {type: "image/svg+xml"}));
  
          const downloadLink = document.createElement("a");
          downloadLink.href = downloadBlob;
          downloadLink.download = download.filename;
          contents.appendChild(downloadLink);
  
          downloadLink.dispatchEvent(
            new MouseEvent('click', { 
              bubbles: true, 
              cancelable: true, 
              view: window 
            })
          );
  
          contents.removeChild(downloadLink);
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
