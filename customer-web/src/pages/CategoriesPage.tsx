/**
 * Categories hub (#/categories) — the full directory behind home's
 * "See all". Cover grid of every category, then product shelves for the
 * first few, MNC-category-landing style. Public, no auth needed.
 */
import { useQuery } from "@tanstack/react-query";
import {
  asArray,
  listCategories,
  listProductsPaged,
  type Category,
  type Product,
} from "../services/api";
import { href } from "../hooks/useHashRoute";
import { EmptyState, ProductCard, Section, Spinner } from "../components/ui";
import { CategoryTilesFromCategories } from "../components/category-tiles";

function CategoryShelf({ category }: { category: Category }) {
  const items = useQuery({
    queryKey: ["products", "category-shelf", category.slug],
    queryFn: () => listProductsPaged({ category: category.slug, page_size: "8" }),
    staleTime: 2 * 60_000,
  });
  const products: Product[] = asArray(
    (items.data as { results?: Product[] } | Product[] | undefined) ?? [],
  ).slice(0, 8);
  if (items.isLoading || items.isError || products.length === 0) return null;
  return (
    <Section
      title={`Top in ${category.name}`}
      action={<a className="link" href={href(`browse?category=${category.slug}`)}>See all</a>}
    >
      <div className="rail">
        {products.map((p) => (
          <div className="rail-item" key={p.id}>
            <ProductCard product={p} />
          </div>
        ))}
      </div>
    </Section>
  );
}

export function CategoriesPage() {
  const catsQuery = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const cats = asArray(catsQuery.data);

  if (catsQuery.isLoading) {
    return (
      <div className="page">
        <Spinner />
      </div>
    );
  }
  if (catsQuery.error || cats.length === 0) {
    return (
      <div className="page">
        <EmptyState
          icon="store"
          title="No categories yet"
          text={catsQuery.error ? "Couldn't load categories." : "Check back soon."}
        />
      </div>
    );
  }

  return (
    <div className="page">
      <div className="pagehead">
        <h1>All categories</h1>
        <p className="muted">
          {cats.length} aisle{cats.length === 1 ? "" : "s"} · everything in one place
        </p>
      </div>
      <Section title="Shop by aisle">
        <CategoryTilesFromCategories categories={cats} style="cover" />
      </Section>
      {cats.slice(0, 4).map((c) => (
        <CategoryShelf key={c.slug} category={c} />
      ))}
    </div>
  );
}
