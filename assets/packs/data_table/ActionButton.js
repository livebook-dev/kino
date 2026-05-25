import { GridCellKind, roundedRect } from "@glideapps/glide-data-grid";
import React from "react";

const BTN_W = 32;
const BTN_H = 22;
const BTN_X_OFFSET = 5;
const BTN_Y_OFFSET = 10;

function isOverButton(posX, posY, rect) {
  const bx = rect.x + BTN_X_OFFSET;
  const by = rect.y + BTN_Y_OFFSET;

  return posX >= bx && posX <= bx + BTN_W && posY >= by && posY <= by + BTN_H;
}

function renderIcon(ctx, rect, spriteManager, theme) {
  theme.accentColor = theme.textDark;

  spriteManager.drawSprite(
    "threeDots",
    "selected",
    ctx,
    rect.x + BTN_X_OFFSET * 2,
    rect.y + BTN_Y_OFFSET,
    theme.headerIconSize,
    theme,
  );
}

const ActionButton = {
  kind: GridCellKind.Custom,
  isMatch: ({ id }) => id === "actions",
  draw: ({ ctx, theme, rect, spriteManager }, _) => {
    ctx.save();
    ctx.beginPath();

    roundedRect(
      ctx,
      rect.x + BTN_X_OFFSET,
      rect.y + BTN_Y_OFFSET,
      BTN_W,
      BTN_H,
      5,
    );

    ctx.strokeStyle = theme.bgHeaderHasFocus;
    ctx.lineWidth = 1;
    ctx.stroke();

    renderIcon(ctx, rect, spriteManager, theme);

    ctx.restore();
    return true;
  },
  onClick: (args) => {
    const { cell, posX, posY, bounds, preventDefault } = args;

    if (isOverButton(bounds.x + posX, bounds.y + posY, bounds)) {
      preventDefault();
      cell.data?.(args);
    }

    return undefined;
  },
};

export default ActionButton;
