import { useEffect, useRef } from "react";

const FOCUSABLE_SELECTOR = [
  "a[href]",
  "area[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "iframe",
  "object",
  "embed",
  "[contenteditable='true']",
  "[tabindex]:not([tabindex='-1'])",
].join(",");

function focusable(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR)).filter(
    (el) => el.getAttribute("aria-hidden") !== "true",
  );
}

/**
 * Shared modal focus trap:
 *   (a) focuses the first focusable element when `active` turns true,
 *   (b) keeps Tab / Shift+Tab inside the container,
 *   (c) closes on Escape,
 *   (d) returns focus to the trigger when it closes.
 *
 * `returnFocusTo` is optional; without it the element that was focused when the
 * modal opened is restored (which is normally the trigger button).
 */
export function useFocusTrap<T extends HTMLElement = HTMLDivElement>(
  active: boolean,
  onClose: () => void,
  returnFocusTo?: { readonly current: HTMLElement | null },
) {
  const containerRef = useRef<T | null>(null);
  const runId = useRef(0);

  useEffect(() => {
    if (!active) return;
    const container = containerRef.current;
    if (!container) return;

    const id = ++runId.current;
    const previouslyFocused =
      returnFocusTo?.current ??
      (document.activeElement instanceof HTMLElement ? document.activeElement : null);

    const first = focusable(container)[0] ?? container;
    first.focus({ preventScroll: true });

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        onClose();
        return;
      }
      if (event.key !== "Tab") return;

      const items = focusable(container);
      if (items.length === 0) {
        event.preventDefault();
        container.focus({ preventScroll: true });
        return;
      }

      const firstItem = items[0];
      const lastItem = items[items.length - 1];
      const current = document.activeElement;

      if (event.shiftKey) {
        if (current === firstItem || !container.contains(current)) {
          event.preventDefault();
          lastItem.focus({ preventScroll: true });
        }
      } else if (current === lastItem || !container.contains(current)) {
        event.preventDefault();
        firstItem.focus({ preventScroll: true });
      }
    };

    document.addEventListener("keydown", onKeyDown, true);

    return () => {
      document.removeEventListener("keydown", onKeyDown, true);
      // StrictMode runs effects twice; only the final cleanup may restore focus
      // (otherwise the first cleanup would steal focus back from the reopened
      // dialog).
      if (id !== runId.current) return;
      if (previouslyFocused && document.contains(previouslyFocused)) {
        window.requestAnimationFrame(() => {
          if (id === runId.current && document.contains(previouslyFocused)) {
            previouslyFocused.focus({ preventScroll: true });
          }
        });
      }
    };
  }, [active, onClose, returnFocusTo]);

  return containerRef;
}
