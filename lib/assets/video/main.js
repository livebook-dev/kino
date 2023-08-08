export function init(ctx, [{ type, opts }, content]) {
  ctx.root.innerHTML = `
    <div class="root">
      <video ${opts} src="${createDataUrl(content, type)}" style="max-height: 500px"/>
    </div>
  `;
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
