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
              <select class="input input--sm" name="chart_type">
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
              <select class="input input--sm" name="data_variable">
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
              <select class="input input--sm" name="x_field">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="x_field_type">
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
              <select class="input input--sm" name="y_field">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="y_field_type">
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
              <select class="input input--sm" name="color_field">
              </select>
            </div>
            <div class="field">
              <label class="input-label">Type</label>
              <select class="input input--sm" name="color_field_type">
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

  const channelFields = ["x_field", "y_field", "color_field"];
  const typeFields = ["x_field_type", "y_field_type", "color_field_type"];

  updateInfoBox(info.missing_dep);
  info.fresh ? setFreshData(info.options) : renderCurrentData(info.fields);

  ctx.root.addEventListener("blur", handleFieldChange, true);
  ctx.root.addEventListener("change", handleFieldChange);

  function handleFieldChange(event) {
    const { name, value } = event.target;
    if (channelFields.includes(name)) { maybeReset(name, value) };
    ctx.pushEvent("update_field", { field: name, value });
  }

  ctx.handleEvent("update", ({ fields }) => {
    clearUnavailableData();
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    updateInfoBox(dep);
  });

  ctx.handleEvent("set_axis_options", ({ options }) => {
    options ? setAxisOptions(options) : missingData();
  });

  ctx.handleEvent("set_available_data", ({ options }) => {
    setAvailableData(options);
  });

  function setValues(fields) {
    for (const field in fields) {
      ctx.root.querySelector(`[name="${field}"]`).value = fields[field];
    }
  }

  function setAvailableData(options) {
    enableAll();
    const selectElem = ctx.root.querySelector(`[name="data_variable"]`);
    const selectedData = selectElem.value;
    const availableData = options[selectedData];
    selectElem.innerHTML = "";
    createOptions(selectElem, Object.keys(options));
    selectElem.value = selectedData;
    if (availableData) {
      setAvailableDataOptions(availableData);
      selectElem.classList.remove("unavailable");
    } else {
      createOptions(selectElem, [selectedData], "unavailable-option");
      selectElem.value = selectedData;
      disableAll();
      selectElem.disabled = false;
      selectElem.classList.add("unavailable");
    }
  }

  function renderCurrentData(fields) {
    disableAll();
    for (const field of channelFields.concat(["data_variable"])) {
      const elem = ctx.root.querySelector(`[name="${field}"]`);
      elem.innerHTML = `<option value="${fields[field]}">${fields[field]}</option>`;
    }
    setValues(fields);
    updateDataInfoBox(fields["data_variable"]);
  }

  function setFreshData(options) {
    enableAll();
    const selectElem = ctx.root.querySelector(`[name="data_variable"]`);
    selectElem.innerHTML = "";
    createOptions(selectElem, Object.keys(options));
    const selected = selectElem.value;
    updateDataInfoBox(options[selected]);
    ctx.pushEvent("update_field", { field: "data_variable", value: selected });
  }

  function setAxisOptions(options) {
    enableAll();
    for (const elem of channelFields) {
      const selectElem = ctx.root.querySelector(`[name="${elem}"]`);
      const inner = elem === "color_field" ? "<option value=''></option>" : "";
      selectElem.innerHTML = inner;
      createOptions(selectElem, options);
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
      selectElem.disabled = (elem === "color_field_type");
      ctx.pushEvent("update_field", { field: elem, value: selected });
    }
  }

  function setAvailableDataOptions(availableData) {
    for (const elem of channelFields) {
      const selectElem = ctx.root.querySelector(`[name="${elem}"]`);
      const selected = selectElem.value;
      const inner = elem === "color_field" ? "<option value=''></option>" : "";
      selectElem.innerHTML = inner;
      createOptions(selectElem, availableData);
      selectElem.value = selected;
      if (selectElem.value === "") {
        createOptions(selectElem, [selected], "unavailable-option");
        selectElem.value = selected;
        selectElem.classList.add("unavailable");
      } else {
        selectElem.classList.remove("unavailable");
      }
    }
  }

  function maybeReset(name, value) {
    const elem = ctx.root.querySelector(`[name="${name}_type"]`);
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

  function createOptions(selectElem, options, elemClass = null) {
    for (const option of options) {
      const element = document.createElement("option");
      element.value = option;
      element.innerText = option;
      if (elemClass) { element.classList.add(elemClass) };
      selectElem.append(element);
    }
  }

  function disableAll() {
    const inputs = ctx.root.querySelectorAll(".input");
    inputs.forEach(input => input.disabled = true);
  }

  function enableAll() {
    const inputs = ctx.root.querySelectorAll(".input");
    inputs.forEach(input => input.disabled = false);
  }

  function clearUnavailableData(params) {
    const unavailableData = ctx.root.querySelectorAll(".unavailable-option");
    const unavailable = ctx.root.querySelectorAll(".unavailable");
    if (unavailableData) { unavailableData.forEach(element => element.remove()) };
    if (unavailable) { unavailable.forEach(element => element.classList.remove("unavailable")) };
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
      infoBox.classList.add("hidden");
    } else {
      disableAll();
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
