export function init(ctx, html) {
  setInnerHTML(ctx.root, html);
}

function setInnerHTML(element, html) {
  // By default setting inner HTML doesn't execute scripts, as
  // noted in [1], however we can work around this by explicitly
  // building the script element.
  //
  // [1]: https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#security_considerations

  element.innerHTML = html;

  Array.from(element.querySelectorAll("script")).reduce((promise, scriptEl) => {
    return promise.then(() => {
      const safeScriptEl = document.createElement("script");

      // If a script is external, we wait for it to load before
      // continuing to insert subsequent scripts.
      const promise = scriptEl.hasAttribute("src")
        ? new Promise((resolve, reject) => {
            safeScriptEl.addEventListener("load", (event) => resolve(), {
              once: true,
            });
          })
        : Promise.resolve();

      Array.from(scriptEl.attributes).forEach((attr) => {
        safeScriptEl.setAttribute(attr.name, attr.value);
      });

      const scriptText = document.createTextNode(scriptEl.innerHTML);
      safeScriptEl.appendChild(scriptText);

      scriptEl.parentNode.replaceChild(safeScriptEl, scriptEl);

      return promise;
    });
  }, Promise.resolve());
}
