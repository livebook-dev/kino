export function init(ctx, [{ type, opts }, content]) {
  ctx.root.innerHTML = `
    <div class="root">
      <audio ${opts} src="${createDataUrl(content, type)}" />
    </div>
  `;

  const audioEl = ctx.root.querySelector("audio");

  ctx.handleEvent("play", () => {
    audioEl.play();
  });

  ctx.handleEvent("pause", () => {
    audioEl.pause();
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
};

function createDataUrl(content, type){
  return `data:${type};base64,${bufferToBase64(content)}`
};
