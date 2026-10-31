import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { asArray, listCategories, type Category } from "../services/api";
import { Icon } from "../components/icons";

/**
 * Left-side category navigation sidebar for browse pages.
 * Shopify/Nike-inspired filter sidebar:
 * - Fixed-width rail (~264px) at desktop
 * - Category tree with active state
 * - Filter groups (price, brand, discount) with pill chips
 * - Sticky positioning within the page
 * - Collapses to a "Hide Filters" toggle on tablet/mobile
 */
export function CategorySidebar({
  activeCategory,
  activeBrand,
  activeDiscount,
  onCategoryChange,
  onBrandChange,
  onDiscountChange,
}: {
  activeCategory: string;
  activeBrand: string;
  activeDiscount: string;
  onCategoryChange: (slug: string) => void;
  onBrandChange: (brand: string) => void;
  onDiscountChange: (discount: string) => void;
}) {
  const { data } = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const categories = asArray<Category>(data);
  const [sideOpen, setSideOpen] = useState(false);
  const sidebarRef = useRef<HTMLDivElement | null>(null);

  // Close sidebar when clicking outside on mobile
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (sidebarRef.current && !sidebarRef.current.contains(e.target as Node)) {
        setSideOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  return (
    <>
      {/* Desktop: sticky left rail */}
      <aside className="filter-side" ref={sidebarRef} aria-label="Filters">
        <div className="filter-group">
          <h4>
            <Icon name="grid" size={13} /> Category
          </h4>
          <div className="filter-opts">
            <label
              className={`filter-opt ${!activeCategory ? "on" : ""}`}
              onClick={() => onCategoryChange("")}
            >
              <input
                type="radio"
                name="f-cat"
                checked={!activeCategory}
                readOnly
              />
              All categories
            </label>
            {categories.map((c) => (
              <label
                key={c.id}
                className={`filter-opt ${activeCategory === c.slug ? "on" : ""}`}
                onClick={() => onCategoryChange(c.slug)}
              >
                <input
                  type="radio"
                  name="f-cat"
                  checked={activeCategory === c.slug}
                  readOnly
                />
                {c.name}
              </label>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="tag" size={13} /> Brand
          </h4>
          <div className="filter-opts">
            <label
              className={`filter-opt ${!activeBrand ? "on" : ""}`}
              onClick={() => onBrandChange("")}
            >
              <input type="radio" name="f-brand" checked={!activeBrand} readOnly />
              All brands
            </label>
            {["Dabur Vatika", "Aswini", "VVD", "Patanjali", "Himalaya"].map((b) => (
              <label
                key={b}
                className={`filter-opt ${activeBrand === b ? "on" : ""}`}
                onClick={() => onBrandChange(b)}
              >
                <input type="radio" name="f-brand" checked={activeBrand === b} readOnly />
                {b}
              </label>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="percent" size={13} /> Discount
          </h4>
          <div className="filter-opts">
            {[
              ["", "Any discount"],
              ["10", "10% off or more"],
              ["25", "25% off or more"],
              ["50", "50% off or more"],
            ].map(([val, label]) => (
              <label
                key={val || "any"}
                className={`filter-opt ${activeDiscount === val ? "on" : ""}`}
                onClick={() => onDiscountChange(val)}
              >
                <input
                  type="radio"
                  name="f-disc"
                  checked={activeDiscount === val}
                  readOnly
                />
                {label}
              </label>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="percent" size={13} /> Price
          </h4>
          <div className="filter-opts">
            <label className="filter-opt" onClick={() => onDiscountChange("price")}>
              <input type="radio" name="f-price" readOnly />
              Under ₹499
            </label>
            <label className="filter-opt" onClick={() => onDiscountChange("price")}>
              <input type="radio" name="f-price" readOnly />
              ₹499 – ₹999
            </label>
            <label className="filter-opt" onClick={() => onDiscountChange("price")}>
              <input type="radio" name="f-price" readOnly />
              ₹999 & above
            </label>
          </div>
        </div>
      </aside>

      {/* Mobile: overlay sidebar */}
      <div className="filter-side-overlay" onClick={() => setSideOpen(false)} />
      <aside className={`filter-side-mobile ${sideOpen ? "open" : ""}`} aria-label="Filters">
        <div className="filter-side-header">
          <h2>Filters</h2>
          <button className="btn-icon" onClick={() => setSideOpen(false)}>
            <Icon name="chevronLeft" size={20} />
          </button>
        </div>
        <div className="filter-group">
          <h4>Category</h4>
          <div className="filter-opts">
            <label
              className={`filter-opt ${!activeCategory ? "on" : ""}`}
              onClick={() => { onCategoryChange(""); setSideOpen(false); }}
            >
              <input type="radio" name="f-cat-m" checked={!activeCategory} readOnly />
              All categories
            </label>
            {categories.map((c) => (
              <label
                key={c.id}
                className={`filter-opt ${activeCategory === c.slug ? "on" : ""}`}
                onClick={() => { onCategoryChange(c.slug); setSideOpen(false); }}
              >
                <input type="radio" name="f-cat-m" checked={activeCategory === c.slug} readOnly />
                {c.name}
              </label>
            ))}
          </div>
        </div>
        <div className="filter-group">
          <h4>Brand</h4>
          <div className="filter-opts">
            <label
              className={`filter-opt ${!activeBrand ? "on" : ""}`}
              onClick={() => { onBrandChange(""); setSideOpen(false); }}
            >
              <input type="radio" name="f-brand-m" checked={!activeBrand} readOnly />
              All brands
            </label>
            {["Dabur Vatika", "Aswini", "VVD", "Patanjali", "Himalaya"].map((b) => (
              <label
                key={b}
                className={`filter-opt ${activeBrand === b ? "on" : ""}`}
                onClick={() => { onBrandChange(b); setSideOpen(false); }}
              >
                <input type="radio" name="f-brand-m" checked={activeBrand === b} readOnly />
                {b}
              </label>
            ))}
          </div>
        </div>
        <div className="filter-group">
          <h4>Discount</h4>
          <div className="filter-opts">
            {[
              ["", "Any discount"],
              ["10", "10% off or more"],
              ["25", "25% off or more"],
              ["50", "50% off or more"],
            ].map(([val, label]) => (
              <label
                key={val || "any"}
                className={`filter-opt ${activeDiscount === val ? "on" : ""}`}
                onClick={() => { onDiscountChange(val); setSideOpen(false); }}
              >
                <input type="radio" name="f-disc-m" checked={activeDiscount === val} readOnly />
                {label}
              </label>
            ))}
          </div>
        </div>
        <div className="filter-group">
          <h4>Price</h4>
          <div className="filter-opts">
            <label className="filter-opt" onClick={() => { onDiscountChange("price"); setSideOpen(false); }}>
              <input type="radio" name="f-price-m" readOnly />
              Under ₹499
            </label>
            <label className="filter-opt" onClick={() => { onDiscountChange("price"); setSideOpen(false); }}>
              <input type="radio" name="f-price-m" readOnly />
              ₹499 – ₹999
            </label>
            <label className="filter-opt" onClick={() => { onDiscountChange("price"); setSideOpen(false); }}>
              <input type="radio" name="f-price-m" readOnly />
              ₹999 & above
            </label>
          </div>
        </div>
        <div style={{ padding: 16 }}>
          <button className="btn btn-primary" style={{ width: "100%" }} onClick={() => setSideOpen(false)}>
            Apply filters
          </button>
        </div>
      </aside>
    </>
  );
}
