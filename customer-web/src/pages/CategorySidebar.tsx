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
 * - Desktop-only on catalog pages; BrowsePage owns its own mobile filter
 *   drawer because it is the only page with working filter state
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

  return (
    <>
      {/* Desktop: sticky left rail */}
      <aside className="filter-side" aria-label="Filters">
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
    </>
  );
}
