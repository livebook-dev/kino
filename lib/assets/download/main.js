export function init(ctx, data) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@500&display=swap");

  ctx.root.innerHTML = `
    <button id="download" class="button">
      <svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18"><path fill="none" d="M0 0h24v24H0z"/><path d="M7 20.981a6.5 6.5 0 0 1-2.936-12 8.001 8.001 0 0 1 15.872 0 6.5 6.5 0 0 1-2.936 12V21H7v-.019zM13 12V8h-2v4H8l4 5 4-5h-3z" fill="rgba(68,86,104,1)"/></svg>
      <span class="text">${data.label}</span>
    </button>
  `;

  const buttonEl = ctx.root.querySelector("#download");

  buttonEl.addEventListener("click", (event) => {
    ctx.pushEvent("download", {});
  });

  ctx.handleEvent("download_content", ([info, arrayBuffer]) => {
    const contentBase64 = bufferToBase64(arrayBuffer);
    download(contentBase64, data.filename);
  });
}

function bufferToBase64(buffer) {
  let binaryString = "";
  const bytes = new Uint8Array(buffer);
  const length = bytes.byteLength;

  for (let i = 0; i < length; i++) {
    binaryString += String.fromCharCode(bytes[i]);
  }

  return btoa(binaryString);
}

function download(contentBase64, filename) {
  const a = document.createElement("a");
  a.href = "data:application/octet-stream;base64," + contentBase64;
  a.download = filename;
  a.click();
}
