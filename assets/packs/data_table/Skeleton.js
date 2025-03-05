/**
 * Creates a loading skeleton for the data table
 */
export function createTableSkeleton() {
  const container = document.createElement("div");
  container.innerHTML = `
    <div class="w-full">
      <table class="w-full border-separate border-spacing-0 mt-2 animate-pulse">
        <tbody>
          ${createTableRow()}
          ${createTableRow()}
          ${createTableRow()}
          ${createTableRow()}
          ${createTableRow()}
        </tbody>
      </table>
    </div>
  `;
  return container;
}

function createTableRow() {
  return `
    <tr>
      ${createDataCell("w-12")}
      ${createDataCell("w-32")}
      ${createDataCell("w-48")}
      ${createDataCell("w-20")}
    </tr>
  `;
}

function createDataCell(width) {
  return `
    <td class="p-2.5 border-b border-slate-100 ${width}">
      <div class="bg-gradient-to-r from-gray-100 via-gray-200 to-gray-100 h-4 rounded">
      </div>
    </td>
  `;
}
