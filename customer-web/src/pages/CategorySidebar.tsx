import { useQuery } from "@tanstack/react-query";
import { navigate } from "../hooks/useHashRoute";
import { asArray, listBrands, listCategories, type Category } from "../services/api";
import { brandNames, FALLBACK_BRANDS } from "../utils/brands";
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
  activeRating = "",
  activeStock = false,
  onCategoryChange,
  onBrandChange,
  onDiscountChange,
  onRatingChange,
  onStockChange,
}: {
  activeCategory: string;
  activeBrand: string;
  activeDiscount: string;
  /** "" = any rating, otherwise "4", "3" or "2". */
  activeRating?: string;
  activeStock?: boolean;
  onCategoryChange: (slug: string) => void;
  onBrandChange: (brand: string) => void;
  onDiscountChange: (discount: string) => void;
  onRatingChange?: (rating: string) => void;
  onStockChange?: (inStock: boolean) => void;
}) {
  const { data } = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const categories = asArray<Category>(data);

  // Brand facet shared with BrowsePage. React Query dedupes the request and
  // the 5-minute stale time keeps sidebar navigation instant. On failure the
  // original hardcoded list is the safety net.
  const brandsQuery = useQuery({
    queryKey: ["brands"],
    queryFn: listBrands,
    staleTime: 5 * 60_000,
  });
  const brands = brandsQuery.isError
    ? FALLBACK_BRANDS
    : brandNames(brandsQuery.data);

  // Pages that only use this rail for navigation (home/search/wishlist) do
  // not own filter state. Send those shoppers to Browse with the facet set so
  // the new controls are never dead UI.
  const goToBrowse = (updates: { rating?: string; stock?: boolean }) => {
    const qs = new URLSearchParams();
    if (activeCategory) qs.set("category", activeCategory);
    if (activeBrand) qs.set("brand", activeBrand);
    if (activeDiscount) qs.set("min_discount", activeDiscount);
    const rating = updates.rating ?? activeRating;
    if (rating) qs.set("min_rating", rating);
    const stock = updates.stock ?? activeStock;
    if (stock) qs.set("in_stock", "true");
    navigate(`browse${qs.toString() ? `?${qs.toString()}` : ""}`);
  };
  const changeRating =
    onRatingChange ?? ((value: string) => goToBrowse({ rating: value }));
  const changeStock =
    onStockChange ?? ((value: boolean) => goToBrowse({ stock: value }));

  return (
    <>
      {/* Desktop: sticky left rail */}
      <aside className="filter-side" aria-label="Filters">
        <div className="filter-group">
          <h4>
            <Icon name="grid" size={13} /> Category
          </h4>
          <div className="filter-opts">
            <label className={`filter-opt ${!activeCategory ? "on" : ""}`}>
              <input
                type="radio"
                name="f-cat"
                value=""
                checked={!activeCategory}
                onChange={() => onCategoryChange("")}
              />
              All categories
            </label>
            {categories.map((c) => (
              <label
                key={c.id}
                className={`filter-opt ${activeCategory === c.slug ? "on" : ""}`}
              >
                <input
                  type="radio"
                  name="f-cat"
                  value={c.slug}
                  checked={activeCategory === c.slug}
                  onChange={() => onCategoryChange(c.slug)}
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
            <label className={`filter-opt ${!activeBrand ? "on" : ""}`}>
              <input
                type="radio"
                name="f-brand"
                value=""
                checked={!activeBrand}
                onChange={() => onBrandChange("")}
              />
              All brands
            </label>
            {brands.map((b) => (
              <label
                key={b}
                className={`filter-opt ${activeBrand === b ? "on" : ""}`}
              >
                <input
                  type="radio"
                  name="f-brand"
                  value={b}
                  checked={activeBrand === b}
                  onChange={() => onBrandChange(b)}
                />
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
              >
                <input
                  type="radio"
                  name="f-disc"
                  value={val}
                  checked={activeDiscount === val}
                  onChange={() => onDiscountChange(val)}
                />
                {label}
              </label>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="star" size={13} /> Rating
          </h4>
          <div className="filter-opts">
            {[
              ["", "Any rating"],
              ["4", "4★ & up"],
              ["3", "3★ & up"],
              ["2", "2★ & up"],
            ].map(([val, label]) => (
              <label
                key={val || "any"}
                className={`filter-opt ${activeRating === val ? "on" : ""}`}
              >
                <input
                  type="radio"
                  name="f-rating"
                  value={val}
                  checked={activeRating === val}
                  onChange={() => changeRating(val)}
                />
                {label}
              </label>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="box" size={13} /> Availability
          </h4>
          <div className="filter-opts">
            <label className={`filter-opt ${activeStock ? "on" : ""}`}>
              <input
                type="checkbox"
                checked={activeStock}
                onChange={(e) => changeStock(e.target.checked)}
              />
              In stock only
            </label>
          </div>
        </div>

        <div className="filter-group">
          <h4>
            <Icon name="percent" size={13} /> Price
          </h4>
          <div className="filter-opts">
            {[
              ["under-499", "Under ₹499"],
              ["499-999", "₹499 – ₹999"],
              ["999-plus", "₹999 & above"],
            ].map(([val, label]) => (
              <label key={val} className="filter-opt">
                <input
                  type="radio"
                  name="f-price"
                  value={val}
                  onChange={() => onDiscountChange("price")}
                />
                {label}
              </label>
            ))}
          </div>
        </div>
      </aside>
    </>
  );
}
