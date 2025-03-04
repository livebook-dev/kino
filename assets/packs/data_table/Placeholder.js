export function createPlaceholder() {
  const placeholderHTML = `
    <div class="w-full">
      <table class="w-full border-separate border-spacing-0 mt-2 animate-pulse">
        <thead>
          <tr class="bg-slate-50 h-[1.5rem]">
          ${createHeaderCell("w-12")}
          ${createHeaderCell("w-32")}
          ${createHeaderCell("w-48")}
          ${createHeaderCell("w-20")}
          </tr>
        </thead>
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

  const container = document.createElement("div");
  container.innerHTML = placeholderHTML.trim();
  return container.firstChild;
}

function createHeaderCell(width) {
  return `
    <th class="p-2.5 ${width}">
      ${cellContent()}
    </th>
  `;
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
      ${cellContent()}
    </td>
  `;
}

function cellContent() {
  return `
    <div class="bg-gradient-to-r from-gray-100 via-gray-200 to-gray-100 h-4 rounded block">
    </div>
  `;
}
