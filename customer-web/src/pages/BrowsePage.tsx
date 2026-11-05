import { useEffect, useRef, useState } from "react";
import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { useHashRoute } from "../hooks/useHashRoute";
import {
  asArray,
  errText,
  listBrands,
  listCategories,
  listProductsPaged,
  type Category,
} from "../services/api";
import { brandNames, FALLBACK_BRANDS } from "../utils/brands";
import { CardSkeletonGrid, EmptyState, PageCrumbs, ProductCard } from "../components/ui";
import { Icon } from "../components/icons";
import { FilterBottomSheet } from "../components/FilterBottomSheet";
export function BrowsePage() {
  const { user } = useAuth();
  const route = useHashRoute();
  const queryString = route.query.toString();

  // Every facet is URL-backed, so a filtered catalog is shareable and the
  // header/sidebar links agree with what is rendered.
  const [category, setCategory] = useState(route.query.get("category") ?? "");
  const [brand, setBrand] = useState(route.query.get("brand") ?? "");
  const [discount, setDiscount] = useState(route.query.get("min_discount") ?? "");
  const [rating, setRating] = useState(route.query.get("min_rating") ?? "");
  const [inStockOnly, setInStockOnly] = useState(route.query.get("in_stock") === "true");
  const [sort, setSort] = useState(route.query.get("sort") ?? "");
  const [minPrice, setMinPrice] = useState(route.query.get("min_price") ?? "");
  const [maxPrice, setMaxPrice] = useState(route.query.get("max_price") ?? "");
  const [featuredOnly, setFeaturedOnly] = useState(route.query.get("is_featured") === "true");
  const [bottomSheetOpen, setBottomSheetOpen] = useState(false);

  // Adopt the hash on navigation (header category links, shared URLs). Doing
  // this in place — instead of remounting — keeps the page's scroll/focus.
  useEffect(() => {
    const q = new URLSearchParams(queryString);
    setCategory(q.get("category") ?? "");
    setBrand(q.get("brand") ?? "");
    setDiscount(q.get("min_discount") ?? "");
    setRating(q.get("min_rating") ?? "");
    setInStockOnly(q.get("in_stock") === "true");
    setSort(q.get("sort") ?? "");
    setMinPrice(q.get("min_price") ?? "");
    setMaxPrice(q.get("max_price") ?? "");
    setFeaturedOnly(q.get("is_featured") === "true");
  }, [queryString]);

  // …and the sidebar writes back. replaceState fires no hashchange, so
  // dispatch one for useHashRoute consumers (header active category).
  useEffect(() => {
    const qs = new URLSearchParams();
    if (category) qs.set("category", category);
    if (brand) qs.set("brand", brand);
    if (discount) qs.set("min_discount", discount);
    if (rating) qs.set("min_rating", rating);
    if (inStockOnly) qs.set("in_stock", "true");
    if (sort === "price_asc" || sort === "price_desc" || sort === "newest" || sort === "rating") {
      qs.set("sort", sort);
    }
    if (minPrice) qs.set("min_price", minPrice);
    if (maxPrice) qs.set("max_price", maxPrice);
    if (featuredOnly) qs.set("is_featured", "true");
    const target = `#/browse${qs.toString() ? `?${qs.toString()}` : ""}`;
    if (window.location.hash !== target) {
      history.replaceState(null, "", target);
      window.dispatchEvent(new HashChangeEvent("hashchange"));
    }
  }, [category, brand, discount, rating, inStockOnly, sort, minPrice, maxPrice, featuredOnly]);

  const categoriesQuery = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const categories = asArray<Category>(categoriesQuery.data);

  const brandsQuery = useQuery({
    queryKey: ["brands"],
    queryFn: listBrands,
    staleTime: 5 * 60_000,
  });
  const brands = brandsQuery.isError
    ? FALLBACK_BRANDS
    : brandNames(brandsQuery.data);

  const baseParams = (): Record<string, string> => {
    const params: Record<string, string> = {};
    if (category) params.category = category;
    if (brand) params.brand = brand;
    if (discount) params.min_discount = discount;
    if (rating) params.min_rating = rating;
    if (inStockOnly) params.in_stock = "true";
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
    ...(rating ? [{ label: `${rating}★ & up`, clear: () => setRating("") }] : []),
    ...(inStockOnly ? [{ label: "In stock only", clear: () => setInStockOnly(false) }] : []),
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
    setRating("");
    setInStockOnly(false);
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

  const categoryName = categories.find((c) => c.slug === category)?.name;

  // Build filter content once for both desktop sidebar and mobile bottom sheet
  const filterContent = (
    <>
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
        <h4><Icon name="star" size={13} /> Rating</h4>
        <div className="filter-opts">
          {[["", "Any rating"], ["4", "4★ & up"], ["3", "3★ & up"], ["2", "2★ & up"]].map(
            ([val, label]) => (
              <label key={val || "any"} className={`filter-opt ${rating === val ? "on" : ""}`}>
                <input
                  type="radio"
                  name="f-rating"
                  checked={rating === val}
                  onChange={() => setRating(val)}
                />
                {label}
              </label>
            ),
          )}
        </div>
      </div>

      <div className="filter-group">
        <h4><Icon name="box" size={13} /> Availability</h4>
        <div className="filter-opts">
          <label className={`filter-opt ${inStockOnly ? "on" : ""}`}>
            <input
              type="checkbox"
              checked={inStockOnly}
              onChange={(e) => setInStockOnly(e.target.checked)}
            />
            In stock only
          </label>
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

      <div className="filter-group">
        <h4><Icon name="sort" size={13} /> Sort By</h4>
        <div className="filter-opts">
          <label className={`filter-opt ${sort === "" ? "on" : ""}`}>
            <input type="radio" name="f-sort" checked={sort === ""} onChange={() => setSort("")} />
            Relevance
          </label>
          <label className={`filter-opt ${sort === "price_asc" ? "on" : ""}`}>
            <input type="radio" name="f-sort" checked={sort === "price_asc"} onChange={() => setSort("price_asc")} />
            Price — Low to High
          </label>
          <label className={`filter-opt ${sort === "price_desc" ? "on" : ""}`}>
            <input type="radio" name="f-sort" checked={sort === "price_desc"} onChange={() => setSort("price_desc")} />
            Price — High to Low
          </label>
          <label className={`filter-opt ${sort === "newest" ? "on" : ""}`}>
            <input type="radio" name="f-sort" checked={sort === "newest"} onChange={() => setSort("newest")} />
            Newest First
          </label>
          <label className={`filter-opt ${sort === "rating" ? "on" : ""}`}>
            <input type="radio" name="f-sort" checked={sort === "rating"} onChange={() => setSort("rating")} />
            Avg. Customer Review
          </label>
        </div>
      </div>
    </>
  );

  return (
    <div className="page">
      <PageCrumbs current={categoryName ?? "Browse products"} />
      <div className="browse-layout">
        {/* Desktop sidebar — hidden on mobile via CSS @media (max-width: 900px) */}
        <aside className="filter-side" aria-label="Filters">
          {filterContent}
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
              {/* Mobile filter button — shown on mobile via CSS */}
              <button
                className="filter-toggle"
                onClick={() => setBottomSheetOpen(true)}
                type="button"
              >
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
                  {f.label} <Icon name="x" size={12} />
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

      {/* Mobile Bottom Sheet for Filters */}
      <FilterBottomSheet
        isOpen={bottomSheetOpen}
        onClose={() => setBottomSheetOpen(false)}
        onApply={() => {
          // Filters are already applied via URL state; just close
        }}
        title="Filter & Sort"
      >
        {filterContent}
      </FilterBottomSheet>
    </div>
  );
}
