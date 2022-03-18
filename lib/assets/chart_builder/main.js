export function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  ctx.root.innerHTML = `
    <div class="app">
      <div id="info-box" class="info-box"></div>
      <div id="data-info-box" class="info-box"></div>
      <div>
        <div class="row">
          <div class="box">
            <div class="field">
              <label class="input-label">Chart</label>
              <select class="input input--sm" name="chart">
                <option value="bar">Bar</option>
                <option value="line">Line</option>
                <option value="point">Point</option>
                <option value="area">Area</option>
              </select>
            </div>
          </div>
          <div class="box">
            <div class="field">
              <label class="input-label">Data</label>
              <select class="input input--sm" name="data">
              </select>
            </div>
          </div>
          <div class="box">
            <div class="field">
              <label class="input-label">Width</label>
              <input class="input input--xs" name="width" type="number" />
            </div>
            <div class="field">
              <label class="input-label">Height</label>
              <input class="input input--xs" name="height" type="number" />
            </div>
          </div>
        </div>
        <div class="row">
          <div class="group">
            <div class="field">
              <label class="input-label">X Axis</label>
              <select class="input input--sm" name="x_axis">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="x_axis_type">
                <option value=""></option>
                <option value="quantitative">Quantitative</option>
                <option value="nominal">Nominal</option>
                <option value="ordinal">Ordinal</option>
              </select>
            </div>
          </div>
          <div class="group">
            <div class="field">
              <label class="input-label">Y Axis</label>
              <select class="input input--sm" name="y_axis">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="y_axis_type">
                <option value=""></option>
                <option value="quantitative">Quantitative</option>
                <option value="nominal">Nominal</option>
                <option value="ordinal">Ordinal</option>
              </select>
            </div>
          </div>
          <div class="group">
            <div class="field">
              <label class="input-label">Color</label>
              <select class="input input--sm" name="color">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="color_type">
                <option value=""></option>
                <option value="quantitative">Quantitative</option>
                <option value="nominal">Nominal</option>
                <option value="ordinal">Ordinal</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  const channelFields = ["x_axis", "y_axis", "color"];
  const typeFields = ["x_axis_type", "y_axis_type", "color_type"];

  updateInfoBox(info.missing_dep);
  info.fresh ? setDataOptions(info.options) : renderDataOptions(info.fields);

  ctx.root.addEventListener("blur", handleFieldChange, true);
  ctx.root.addEventListener("change", handleFieldChange);

  function handleFieldChange(event) {
    const { name, value } = event.target;
    if (channelFields.includes(name)) { maybeReset({name, value}) }
    ctx.pushEvent("update_field", { field: name, value });
  }

  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    updateInfoBox(dep);
  });

  ctx.handleEvent("set_axis_options", ({ options }) => {
    options ? setAxisOptions(options) : missingData();
  });

  ctx.handleEvent("set_data_options", ({ options }) => {
    setDataOptions(options);
  });

  function setValues(fields) {
    for (const field in fields) {
      ctx.root.querySelector(`[name="${field}"]`).value = fields[field];
    }
  }

  function renderDataOptions(fields) {
    for (const field of channelFields.concat(["data"])) {
      const elem = ctx.root.querySelector(`[name="${field}"]`);
      elem.innerHTML = `<option value="${fields[field]}">${fields[field]}</option>`
    }
    const inputs = ctx.root.querySelectorAll(".input");
    inputs.forEach(input => input.disabled = true);
    setValues(fields);
    updateDataInfoBox(fields["data"]);
  }

  function setDataOptions(options) {
    const inputs = ctx.root.querySelectorAll(".input");
    inputs.forEach(input => input.disabled = false);
    const selectElem = ctx.root.querySelector(`[name="data"]`);
    selectElem.innerHTML = "";
    createOptions(selectElem, Object.keys(options))
    const selected = selectElem.value;
    updateDataInfoBox(options);
    ctx.pushEvent("update_field", { field: "data", value: selected });
  }

  function setAxisOptions(options) {
    for (const elem of channelFields) {
      const selectElem = ctx.root.querySelector(`[name="${elem}"]`);
      selectElem.disabled = false;
      selectElem.innerHTML = "<option value=''></option>";
      createOptions(selectElem, options)
      elem === "color" ? selectElem.selectedIndex = 0 : selectElem.selectedIndex = 1;
      const selected = selectElem.value;
      ctx.pushEvent("update_field", { field: elem, value: selected });
    }
    setTypes();
  }

  function setTypes() {
    for (const elem of typeFields) {
      const selectElem = ctx.root.querySelector(`[name="${elem}"]`);
      selectElem.selectedIndex = 0;
      const selected = selectElem.value;
      elem === "color_type" ? selectElem.disabled = true : selectElem.disabled = false;
      ctx.pushEvent("update_field", { field: elem, value: selected });
    }
  }

  function maybeReset( {name, value} ) {
    const elem = ctx.root.querySelector(`[name="${name}_type"]`)
    value === "" ? resetField(elem) : elem.disabled = false;
  }

  function missingData() {
    for (const name of channelFields.concat(typeFields)) {
      const elem = ctx.root.querySelector(`[name="${name}"]`);
      resetField(elem);
    }
    updateDataInfoBox();
  }

  function resetField(elem) {
    elem.value = "";
    elem.disabled = true;
    ctx.pushEvent("update_field", { field: elem.name, value: "" });
  }

  function createOptions(selectElem, options) {
    for (const option of options) {
      const element = document.createElement("option");
      element.innerText = option;
      selectElem.append(element);
    }
  }

  function updateInfoBox(dep) {
    const infoBox = ctx.root.querySelector("#info-box");

    if (dep) {
      infoBox.classList.remove("hidden");
      infoBox.textContent = `To successfully build charts, you need to add the following dependency:\n\n    ${dep}`;
    } else {
      infoBox.classList.add("hidden");
    }
  }

  function updateDataInfoBox(data = null) {
    const infoBox = ctx.root.querySelector("#data-info-box");
    if (data) {
      infoBox.classList.add("hidden")
    } else {
      infoBox.classList.remove("hidden");
      infoBox.textContent =
`To successfully plot graphs, you need at least one dataset available.

The dataset needs to be a map of series, for exemple:
    my_data = %{
      a: [89, 124, 09, 67, 45],
      b: [12, 45, 67, 83, 32]
    }

Or using Explorer:
    iris = Explorer.Datasets.iris() |> Explorer.DataFrame.to_map()`;
    }
  }
}
