import "https://cdn.jsdelivr.net/npm/vega@5.21.0";
import "https://cdn.jsdelivr.net/npm/vega-lite@5.2.0";
import "https://cdn.jsdelivr.net/npm/vega-embed@6.20.2";

// See https://github.com/vega/vega-lite/blob/b61b13c2cbd4ecde0448544aff6cdaea721fd22a/src/compile/data/assemble.ts#L228-L231
const DEFAULT_DATASET_NAME = "source_0";

const throttledResize = throttle((view) => view.resize(), 1_000);

export function init(ctx, data) {
  const { spec, datasets } = data;

  if (!spec.data) {
    spec.data = { values: [] };
  }

  const options = {
    actions: { export: true, source: false, compiled: false, editor: false },
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
