import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import {
  asArray,
  errText,
  listCategories,
  listProductsPaged,
  type Category,
  type Product,
} from "../services/api";
import { CardSkeletonGrid, EmptyState, ProductCard, Section, SignInGate } from "../components/ui";
export function BrowsePage({ initialCategory }: { initialCategory?: string }) {
  const { user } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [category, setCategory] = useState(initialCategory ?? "");
  const [sort, setSort] = useState("");
  const [minPrice, setMinPrice] = useState("");
  const [maxPrice, setMaxPrice] = useState("");
  const [featuredOnly, setFeaturedOnly] = useState(false);
  const [products, setProducts] = useState<Product[] | null>(null);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const baseParams = (): Record<string, string> => {
    const params: Record<string, string> = {};
    if (category) params.category = category;
    if (sort === "price_asc" || sort === "price_desc" || sort === "newest") params.sort = sort;
    if (minPrice) params.min_price = minPrice;
    if (maxPrice) params.max_price = maxPrice;
    if (featuredOnly) params.is_featured = "true";
    return params;
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
  }, [user, category, sort, minPrice, maxPrice, featuredOnly]);

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
  }, [user]);

  if (!user) return <SignInGate title="Browse the catalog" text="Sign in to see products and prices." />;

  return (
    <div className="page">
      <div className="pagehead">
        <h1>Browse</h1>
        <p className="muted">{category ? `Category: ${category}` : "Everything in the catalog"}</p>
      </div>

      <div className="toolbar">
        <select value={category} onChange={(e) => setCategory(e.target.value)} aria-label="Category">
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.slug}>{c.name}</option>
          ))}
        </select>
        <select value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Sort">
          <option value="">Sort: default</option>
          <option value="price_asc">Price: low → high</option>
          <option value="price_desc">Price: high → low</option>
          <option value="newest">Newest</option>
        </select>
        <input type="number" min="0" placeholder="Min ₹" style={{ width: 90 }} value={minPrice} onChange={(e) => setMinPrice(e.target.value)} />
        <input type="number" min="0" placeholder="Max ₹" style={{ width: 90 }} value={maxPrice} onChange={(e) => setMaxPrice(e.target.value)} />
        <label style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13.5 }}>
          <input type="checkbox" checked={featuredOnly} onChange={(e) => setFeaturedOnly(e.target.checked)} />
          Featured only
        </label>
      </div>

      {error ? (
        <EmptyState icon="warning" title="Couldn't load products" text={error} />
      ) : products === null ? (
        <CardSkeletonGrid />
      ) : products.length === 0 ? (
        <EmptyState icon="search" title="No products found" text="Try clearing the filters." />
      ) : (
        <Section>
          <p className="muted" style={{ margin: "0 0 10px" }}>
            Showing {products.length} of {total}
          </p>
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
        </Section>
      )}
    </div>
  );
}
