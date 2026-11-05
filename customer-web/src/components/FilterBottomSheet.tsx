import { useEffect, useState, type ReactNode } from "react";
import { Dialog, Transition } from "@headlessui/react";
import { Fragment } from "react";
import { Icon } from "./icons";
import { clsx } from "clsx";

interface FilterBottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  onApply: () => void;
  children: ReactNode;
  title?: string;
}

export function FilterBottomSheet({
  isOpen,
  onClose,
  onApply,
  children,
  title = "Filter & Sort",
}: FilterBottomSheetProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    return () => setMounted(false);
  }, []);

  if (!mounted) return null;

  return (
    <Transition.Root show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="transition-opacity ease-linear duration-200"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="transition-opacity ease-linear duration-150"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
        </Transition.Child>

        <div className="fixed inset-x-0 bottom-0 z-50">
          <Transition.Child
            as={Fragment}
            enter="transition ease-in-out duration-300"
            enterFrom="opacity-0 translate-y-full"
            enterTo="opacity-100 translate-y-0"
            leave="transition ease-in-out duration-200"
            leaveFrom="opacity-100 translate-y-0"
            leaveTo="opacity-0 translate-y-full"
          >
            <Dialog.Panel
              className={clsx(
                "relative bg-surface rounded-t-2xl shadow-xl",
                "overflow-hidden max-h-[85vh] flex flex-col",
              )}
            >
              {/* Handle bar */}
              <div
                className="w-10 h-1.5 mx-auto mt-4 mb-2 bg-border rounded-full"
                aria-hidden="true"
              />

              {/* Header */}
              <div className="flex items-center justify-between px-5 pb-3 border-b border-border">
                <h2 className="font-display text-xl font-semibold">{title}</h2>
                <button
                  type="button"
                  className="p-2 rounded-full hover:bg-sunken transition-colors"
                  onClick={onClose}
                  aria-label="Close filters"
                >
                  <Icon name="x" size={22} />
                </button>
              </div>

              {/* Content - scrollable */}
              <div className="flex-1 overflow-y-auto px-5 py-4">
                {children}
              </div>

              {/* Apply button - sticky at bottom */}
              <div className="border-t border-border p-4 safe-area-bottom">
                <button
                  type="button"
                  onClick={() => {
                    onApply();
                    onClose();
                  }}
                  className="btn btn-primary btn-block"
                  style={{ minHeight: "52px", fontSize: "16px" }}
                >
                  Show Results
                </button>
              </div>
            </Dialog.Panel>
          </Transition.Child>
        </div>
      </Dialog>
    </Transition.Root>
  );
}