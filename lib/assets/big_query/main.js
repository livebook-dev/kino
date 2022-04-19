export function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  ctx.root.innerHTML = `
    <div class="app">
      <div id="info-box" class="info-box"></div>
      <div class="container">
        <div class="row header">
          <div class="field">
            <label class="input-label"> Assign to </label>
            <input class="input input--xs input--text" name="variable" type="text" />
          </div>
        </div>
        <div class="row mixed-row">
          <div class="field grow">
            <label class="input-label">Project ID</label>
            <input class="input" name="project_id" type="text" />
          </div>
          <div class="field grow">
            <label class="input-label">Dataset</label>
            <input class="input" name="dataset" type="text" />
          </div>
        </div>
        <div class="row">
          <div class="field grow">
            <label class="input-label">Private Key ID</label>
            <input class="input" name="private_key_id" type="password" />
          </div>
          <div class="field grow">
            <label class="input-label">Private Key</label>
            <input class="input" name="private_key" type="password" />
          </div>
        </div>
        <div class="row">
          <div class="field grow">
            <label class="input-label">Client E-mail</label>
            <input class="input" name="client_email" type="text" />
          </div>
          <div class="field grow">
            <label class="input-label">Client ID</label>
            <input class="input" name="client_id" type="text" />
          </div>
        </div>
        <div class="row">
          <div class="field grow">
            <label class="input-label">Client x509 Certificate URL</label>
            <input class="input" name="client_x509_cert_url" type="text" />
          </div>
        </div>
      </div>
    </div>
  `;

  updateInfoBox(info.missing_dep);
  setValues(info.fields);

  ctx.root.addEventListener("blur", handleFieldChange, true);
  ctx.root.addEventListener("change", handleFieldChange);

  function handleFieldChange(event) {
    const { name, value } = event.target;

    ctx.pushEvent("update_field", { field: name, value });
  }

  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    updateInfoBox(dep);
  });

  function setValues(fields) {
    for (const field in fields) {
      ctx.root.querySelector(`[name="${field}"]`).value = fields[field];
    }
  }

  function updateInfoBox(dep) {
    const infoBox = ctx.root.querySelector("#info-box");

    if (dep) {
      infoBox.classList.remove("hidden");
      infoBox.innerHTML = `<p>To successfully connect, you need to add the following dependency:</p><span>${dep}</span>`;
    } else {
      infoBox.classList.add("hidden");
    }
  }
}
