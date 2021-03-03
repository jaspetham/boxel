import ContextAwareBounds from '../models/context-aware-bounds';

function runWithoutAnimations(element: HTMLElement, f: () => DOMRect) {
  let animations = element.getAnimations();
  let currentTimes: number[] = [];
  animations.forEach((a) => {
    a.pause();
    currentTimes.push(a.currentTime || 0);
    let timing = a.effect && a.effect.getComputedTiming();
    if (timing) {
      a.currentTime = (timing.delay || 0) + (timing.activeDuration || 0);
    }
  });
  let result = f();
  for (let i = 0; i < animations.length; i++) {
    animations[i].currentTime = currentTimes[i];
    animations[i].play();
  }
  return result;
}

function getDocumentPosition(
  element: HTMLElement,
  opts = { withAnimations: false }
) {
  let wrapper = (_el: HTMLElement, f: () => DOMRect) => f();
  if (opts.withAnimations === false) {
    wrapper = runWithoutAnimations;
  }
  return wrapper(element, () => {
    let rect = element.getBoundingClientRect();

    return new DOMRect(
      rect.left + window.scrollX,
      rect.top + window.scrollY,
      rect.width,
      rect.height
    );
  });
}

type MeasureArgs = {
  contextElement: HTMLElement;
  element: HTMLElement;
  withAnimations?: boolean;
};

export function measure({
  contextElement,
  element,
  withAnimations = false,
}: MeasureArgs): ContextAwareBounds {
  return new ContextAwareBounds({
    element: getDocumentPosition(element, { withAnimations }),
    contextElement: getDocumentPosition(contextElement),
  });
}
