import "https://cdn.jsdelivr.net/npm/vega@5.21.0";
import "https://cdn.jsdelivr.net/npm/vega-lite@5.2.0";
import "https://cdn.jsdelivr.net/npm/vega-embed@6.20.2";

// See https://github.com/vega/vega-lite/blob/b61b13c2cbd4ecde0448544aff6cdaea721fd22a/src/compile/data/assemble.ts#L228-L231
const DEFAULT_DATASET_NAME = "source_0";

const throttledResize = throttle((view) => view.resize(), 1_000);

const color = {
  "blue300": "#b2c1ff",
  "blue400": "#8ba2ff",
  "blue500": "#6583ff",
  "blue600": "#3E64ff",
  "blue700": "#2d4cdb",
  "blue800": "#1f37b7",
  "blue900": "#132593",
  "yellow600": "#ffa83f",
  "yellow800": "#b7641f",
  "red500": "#e2474d",
  "red700": "#bc1227",
  "green500": "#4aa148",
  "green700": "#137518",
  "gray200": "#e1e8f0",
  "gray600": "#445668",
  "gray800": "#1c2a3a",
  "gray900": "#0d1829",
};

const primaryColors = [
  color.blue500,
  color.yellow600,
  color.red500,
  color.green500,
  color.blue700,
  color.yellow800,
  color.red700,
  color.green700,
];

const blues = [
  color.blue300,
  color.blue400,
  color.blue500,
  color.blue600,
  color.blue700,
  color.blue800,
  color.blue900,
];

const markColor = color.blue500;

const livebookTheme = {
  background: "#fff",

  title: {
    anchor: "center",
    fontSize: 18,
    fontWeight: 400,
    color: color.gray600,
    fontFamily: "Inter",
    font: "Inter",
  },

  arc: {fill: markColor},
  area: {fill: markColor},
  line: {stroke: markColor, strokeWidth: 2},
  path: {stroke: markColor},
  rect: {fill: markColor},
  shape: {stroke: markColor},
  symbol: {fill: markColor, strokeWidth: 1.5, size: 50},
  bar: {fill: markColor, stroke: null},
  circle: {fill: markColor},
  tick: {fill: markColor},
  rule: {color: color.gray900},
  text: {color: color.gray900},

  axisBand: {
    grid: false,
    tickExtra: true,
  },

  legend: {
    titleFontWeight: 400,
    titleFontColor: color.gray600,
    titleFontSize: 13,
    titlePadding: 10,
    labelBaseline: "middle",
    labelFontSize: 12,
    symbolSize: 100,
    symbolType: "circle",
  },

  axisY: {
    gridColor: color.gray200,
    titleFontSize: 12,
    titlePadding: 10,
    labelFontSize: 12,
    labelPadding: 8,
    titleColor: color.gray800,
    titleFontWeight: 400,
  },

  axisX: {
    domain: true,
    domainColor: color.gray200,
    titlePadding: 10,
    titleColor: color.gray800,
    titleFontWeight: 400,
  },

  range: {
    category: primaryColors,
    ramp: blues,
    ordinal: blues,
  },
};

export function init(ctx, data) {
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  const { spec, datasets } = data;

  if (!spec.data) {
    spec.data = { values: [] };
  }

  const options = {
    actions: { export: true, source: false, compiled: false, editor: false },
    config: livebookTheme,
  };

  vegaEmbed(ctx.root, spec, options)
    .then((result) => {
      const view = result.view;

      datasets.forEach(([dataset, data]) => {
        view.resize();
        view.data(dataset || DEFAULT_DATASET_NAME, data).run();
      });

      ctx.handleEvent("push", ({ data, dataset, window }) => {
        dataset = dataset || DEFAULT_DATASET_NAME;

        const currentData = view.data(dataset);
        const changeset = buildChangeset(currentData, data, window);
        // Schedule resize after the run finishes
        throttledResize(view);
        view.change(dataset, changeset).run();
      });
    })
    .catch((error) => {
      const message = `Failed to render the given Vega-Lite specification, got the following error:\n\n    ${error.message}\n\nMake sure to check for typos.`;

      ctx.root.innerHTML = `
        <div style="color: #FF3E38; white-space: pre-wrap;">${message}</div>
      `;
    });
};

function buildChangeset(currentData, newData, window) {
  if (window === 0) {
    return vega.changeset().remove(currentData);
  } else if (window) {
    const toInsert = newData.slice(-window);
    const freeSpace = Math.max(window - toInsert.length, 0);
    const toRemove = currentData.slice(0, -freeSpace);

    return vega.changeset().remove(toRemove).insert(toInsert);
  } else {
    return vega.changeset().insert(newData);
  }
}

/**
* A simple throttle version that ensures the given function
* is called at most once within the given time window.
*/
export function throttle(fn, windowMs) {
  let ignore = false;

  return (...args) => {
    if (!ignore) {
      fn(...args);
      ignore = true;
      setTimeout(() => {
        ignore = false;
      }, windowMs);
    }
  };
}
