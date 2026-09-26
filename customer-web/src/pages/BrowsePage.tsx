import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import {
  asArray,
  errText,
  listBrands,
  listCategories,
  listProductsPaged,
  type Category,
  type Product,
} from "../services/api";
import { CardSkeletonGrid, EmptyState, ProductCard, SignInGate } from "../components/ui";
import { Icon } from "../components/icons";
export function BrowsePage({ initialCategory }: { initialCategory?: string }) {
  const { user } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<string[]>([]);
  const [category, setCategory] = useState(initialCategory ?? "");
  const [brand, setBrand] = useState("");
  const [discount, setDiscount] = useState("");
  const [sort, setSort] = useState("");
  const [minPrice, setMinPrice] = useState("");
  const [maxPrice, setMaxPrice] = useState("");
  const [featuredOnly, setFeaturedOnly] = useState(false);
  const [products, setProducts] = useState<Product[] | null>(null);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sideOpen, setSideOpen] = useState(false);

  const baseParams = (): Record<string, string> => {
    const params: Record<string, string> = {};
    if (category) params.category = category;
    if (brand) params.brand = brand;
    if (discount) params.min_discount = discount;
    if (sort === "price_asc" || sort === "price_desc" || sort === "newest") params.sort = sort;
    if (minPrice) params.min_price = minPrice;
    if (maxPrice) params.max_price = maxPrice;
    if (featuredOnly) params.is_featured = "true";
    return params;
  };

  const activeFilters: { label: string; clear: () => void }[] = [
    ...(category
      ? [{
        label: `Category: ${categories.find((c) => c.slug === category)?.name ?? category}`,
        clear: () => setCategory(""),
      }]
      : []),
    ...(brand ? [{ label: `Brand: ${brand}`, clear: () => setBrand("") }] : []),
    ...(discount ? [{ label: `${discount}% off or more`, clear: () => setDiscount("") }] : []),
    ...(featuredOnly ? [{ label: "Featured", clear: () => setFeaturedOnly(false) }] : []),
    ...((minPrice || maxPrice)
      ? [{
        label: `₹${minPrice || "0"} – ₹${maxPrice || "∞"}`,
        clear: () => {
          setMinPrice("");
          setMaxPrice("");
        },
      }]
      : []),
  ];

  const clearAll = () => {
    setCategory("");
    setBrand("");
    setDiscount("");
    setSort("");
    setMinPrice("");
    setMaxPrice("");
    setFeaturedOnly(false);
  };

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    setError(null);
    setProducts(null);
    setPage(1);
    listProductsPaged(baseParams())
      .then((d) => {
        if (cancelled) return;
        setProducts(d.results);
        setTotal(d.count);
      })
      .catch((e) => {
        if (!cancelled) setError(errText(e));
      });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user, category, brand, discount, sort, minPrice, maxPrice, featuredOnly]);

  async function loadMore() {
    if (loadingMore) return;
    setLoadingMore(true);
    try {
      const d = await listProductsPaged({ ...baseParams(), page: String(page + 1) });
      setProducts((prev) => [...(prev ?? []), ...d.results]);
      setTotal(d.count);
      setPage((p) => p + 1);
    } catch (e) {
      setError(errText(e));
    } finally {
      setLoadingMore(false);
    }
  }

  useEffect(() => {
    if (initialCategory !== undefined) setCategory(initialCategory);
  }, [initialCategory]);

  useEffect(() => {
    if (!user) return;
    listCategories()
      .then((d) => setCategories(asArray(d)))
      .catch(() => setCategories([]));
    listBrands()
      .then((d) => setBrands(asArray(d).map((b) => b.name)))
      .catch(() => setBrands([]));
  }, [user]);

  if (!user) return <SignInGate title="Browse the catalog" text="Sign in to see products and prices." />;

  const categoryName = categories.find((c) => c.slug === category)?.name;

  return (
    <div className="page">
      <div className="browse-layout">
        <aside className={`filter-side ${sideOpen ? "open" : ""}`} aria-label="Filters">
          <div className="filter-group">
            <h4><Icon name="grid" size={13} /> Category</h4>
            <div className="filter-opts">
              <label className={`filter-opt ${!category ? "on" : ""}`}>
                <input type="radio" name="f-cat" checked={!category} onChange={() => setCategory("")} />
                All categories
              </label>
              {categories.map((c) => (
                <label key={c.id} className={`filter-opt ${category === c.slug ? "on" : ""}`}>
                  <input
                    type="radio"
                    name="f-cat"
                    checked={category === c.slug}
                    onChange={() => setCategory(c.slug)}
                  />
                  {c.name}
                </label>
              ))}
            </div>
          </div>

          <div className="filter-group">
            <h4><Icon name="tag" size={13} /> Brand</h4>
            <div className="filter-opts">
              <label className={`filter-opt ${!brand ? "on" : ""}`}>
                <input type="radio" name="f-brand" checked={!brand} onChange={() => setBrand("")} />
                All brands
              </label>
              {brands.map((b) => (
                <label key={b} className={`filter-opt ${brand === b ? "on" : ""}`}>
                  <input type="radio" name="f-brand" checked={brand === b} onChange={() => setBrand(b)} />
                  {b}
                </label>
              ))}
            </div>
          </div>

          <div className="filter-group">
            <h4><Icon name="percent" size={13} /> Discount</h4>
            <div className="filter-opts">
              {[["", "Any discount"], ["10", "10% off or more"], ["25", "25% off or more"], ["50", "50% off or more"]].map(
                ([val, label]) => (
                  <label key={val || "any"} className={`filter-opt ${discount === val ? "on" : ""}`}>
                    <input
                      type="radio"
                      name="f-disc"
                      checked={discount === val}
                      onChange={() => setDiscount(val)}
                    />
                    {label}
                  </label>
                ),
              )}
            </div>
          </div>

          <div className="filter-group">
            <h4><Icon name="percent" size={13} /> Price</h4>
            <div style={{ display: "flex", gap: 8 }}>
              <input
                type="text"
                inputMode="numeric"
                placeholder="Min ₹"
                value={minPrice}
                onChange={(e) => setMinPrice(e.target.value.replace(/\D/g, ""))}
              />
              <input
                type="text"
                inputMode="numeric"
                placeholder="Max ₹"
                value={maxPrice}
                onChange={(e) => setMaxPrice(e.target.value.replace(/\D/g, ""))}
              />
            </div>
          </div>

          <div className="filter-group">
            <div className="filter-opts">
              <label className={`filter-opt ${featuredOnly ? "on" : ""}`}>
                <input
                  type="checkbox"
                  checked={featuredOnly}
                  onChange={(e) => setFeaturedOnly(e.target.checked)}
                />
                Featured only
              </label>
            </div>
          </div>
        </aside>

        <div className="browse-main">
          <div className="sortbar">
            <span className="count">
              {categoryName ? (
                <>Showing <b>{total}</b> in <b>{categoryName}</b></>
              ) : (
                <>Showing <b>{total}</b> products</>
              )}
            </span>
            <div className="sortbar-right">
              <button className="filter-toggle" onClick={() => setSideOpen((o) => !o)} type="button">
                <Icon name="grid" size={14} /> Filters
              </button>
              <label htmlFor="sortsel">Sort By</label>
              <select id="sortsel" value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Sort">
                <option value="">Relevance</option>
                <option value="price_asc">Price — Low to High</option>
                <option value="price_desc">Price — High to Low</option>
                <option value="newest">Newest First</option>
              </select>
            </div>
          </div>

          {activeFilters.length > 0 && (
            <div className="filter-chips">
              {activeFilters.map((f) => (
                <button key={f.label} className="filter-chip" onClick={f.clear} title="Remove filter">
                  {f.label} ✕
                </button>
              ))}
              <button className="link" onClick={clearAll}>Clear all</button>
            </div>
          )}

          {error ? (
            <EmptyState icon="warning" title="Couldn't load products" text={error} />
          ) : products === null ? (
            <CardSkeletonGrid />
          ) : products.length === 0 ? (
            <EmptyState icon="search" title="No products found" text="Try clearing the filters." />
          ) : (
            <>
              <div className="grid grid-products">
                {products.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
              {products.length < total && (
                <div style={{ display: "flex", justifyContent: "center", marginTop: 18 }}>
                  <button className="btn" onClick={loadMore} disabled={loadingMore}>
                    {loadingMore ? "Loading…" : `Load more (${total - products.length} left)`}
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
