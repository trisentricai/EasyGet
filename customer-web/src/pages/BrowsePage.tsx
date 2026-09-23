import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import {
  asArray,
  errText,
  listCategories,
  listProducts,
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
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialCategory !== undefined) setCategory(initialCategory);
  }, [initialCategory]);

  useEffect(() => {
    if (!user) return;
    listCategories()
      .then((d) => setCategories(asArray(d)))
      .catch(() => setCategories([]));
  }, [user]);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    setError(null);
    setProducts(null);
    const params: Record<string, string> = {};
    if (category) params.category = category;
    if (sort === "price_asc" || sort === "price_desc" || sort === "newest") params.sort = sort;
    if (minPrice) params.min_price = minPrice;
    if (maxPrice) params.max_price = maxPrice;
    if (featuredOnly) params.is_featured = "true";
    listProducts(params)
      .then((d) => {
        if (!cancelled) setProducts(asArray(d));
      })
      .catch((e) => {
        if (!cancelled) setError(errText(e));
      });
    return () => {
      cancelled = true;
    };
  }, [user, category, sort, minPrice, maxPrice, featuredOnly]);

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
          <div className="grid grid-products">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </Section>
      )}
    </div>
  );
}
