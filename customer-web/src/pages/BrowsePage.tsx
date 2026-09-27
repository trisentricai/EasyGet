import { useEffect, useRef, useState } from "react";
import { useInfiniteQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import {
  asArray,
  errText,
  listBrands,
  listCategories,
  listProductsPaged,
  type Category,
} from "../services/api";
import { CardSkeletonGrid, EmptyState, ProductCard } from "../components/ui";
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
  const [sideOpen, setSideOpen] = useState(false);

  const baseParams = (): Record<string, string> => {
    const params: Record<string, string> = {};
    if (category) params.category = category;
    if (brand) params.brand = brand;
    if (discount) params.min_discount = discount;
    if (sort === "price_asc" || sort === "price_desc" || sort === "newest" || sort === "rating") params.sort = sort;
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

  const params = baseParams();
  const [total, setTotal] = useState(0);

  const { data, error, hasNextPage, isFetchingNextPage, fetchNextPage } = useInfiniteQuery({
    queryKey: ["products", "browse", params, user?.id ?? null],
    queryFn: ({ pageParam }) => listProductsPaged({ ...params, page: String(pageParam) }),
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages) => (lastPage.next ? allPages.length + 1 : undefined),
  });

  const products = data ? data.pages.flatMap((p) => p.results) : null;
  const dataTotal = data ? data.pages[data.pages.length - 1].count : null;
  if (dataTotal !== null && dataTotal !== total) setTotal(dataTotal);
  const errorMsg = error ? errText(error) : null;

  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const [nearBottom, setNearBottom] = useState(false);

  // Observe a 1px sentinel just below the grid; rootMargin pre-fetches
  // when the user is within ~200px of the bottom.
  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    const io = new IntersectionObserver(([entry]) => setNearBottom(entry.isIntersecting), {
      rootMargin: "0px 0px 200px 0px",
    });
    io.observe(el);
    return () => io.disconnect();
  }, [hasNextPage]);

  // Auto-fetch while the sentinel stays in view; isFetchingNextPage is the
  // loading guard (React Query also dedupes in-flight page fetches).
  useEffect(() => {
    if (!data || !nearBottom || !hasNextPage || isFetchingNextPage) return;
    void fetchNextPage();
  }, [data, nearBottom, hasNextPage, isFetchingNextPage, fetchNextPage]);

  function loadMore() {
    if (isFetchingNextPage) return;
    void fetchNextPage();
  }

  useEffect(() => {
    if (initialCategory !== undefined) setCategory(initialCategory);
  }, [initialCategory]);

  useEffect(() => {
    listCategories()
      .then((d) => setCategories(asArray(d)))
      .catch(() => setCategories([]));
    listBrands()
      .then((d) => setBrands(asArray(d).map((b) => b.name)))
      .catch(() => setBrands([]));
  }, []);

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
                <option value="rating">Avg. Customer Review</option>
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

          {errorMsg ? (
            <EmptyState icon="warning" title="Couldn't load products" text={errorMsg} />
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
              {hasNextPage && <div ref={sentinelRef} style={{ height: 1 }} aria-hidden="true" />}
              {hasNextPage && !nearBottom && (
                <div style={{ display: "flex", justifyContent: "center", marginTop: 18 }}>
                  <button className="btn" onClick={loadMore} disabled={isFetchingNextPage}>
                    {isFetchingNextPage ? "Loading…" : `Load more (${total - products.length} left)`}
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
