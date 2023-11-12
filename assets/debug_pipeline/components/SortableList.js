import React, { useMemo, useState } from "react";
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  closestCenter,
  defaultDropAnimationSideEffects,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";

export default function SortableList({ items, onDrop, render }) {
  const [active, setActive] = useState(null);
  const activeItem = useMemo(
    () => items.find((item) => item.id === active?.id),
    [active, items]
  );

  const dropAnimationConfig = {
    sideEffects: defaultDropAnimationSideEffects({
      styles: {
        active: {
          opacity: "0.4",
        },
      },
    }),
  };

  // Add a small drag threshold, so that regular click is not intercepted
  // (see https://github.com/clauderic/dnd-kit/issues/591#issuecomment-1017050816)
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 },
    })
  );

  return (
    <DndContext
      collisionDetection={closestCenter}
      sensors={sensors}
      onDragStart={({ active }) => setActive(active)}
      onDragEnd={({ active, over }) => onDrop(active.id, over.id)}
    >
      <div>
        <SortableContext
          items={items.map((item) => item.id)}
          strategy={verticalListSortingStrategy}
        >
          {items.map((item, index) => render(item, index))}
        </SortableContext>
        <DragOverlay dropAnimation={dropAnimationConfig}>
          {activeItem && render(activeItem, items.indexOf(activeItem))}
        </DragOverlay>
      </div>
    </DndContext>
  );
}
