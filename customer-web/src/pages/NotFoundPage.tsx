import { EmptyState } from "../components/ui";
import { navigate } from "../hooks/useHashRoute";

/**
 * Fallback for unknown hash routes — e.g. `#/product/typo-slug` that still
 * parses as a product route is handled by the PDP; this catches routes that
 * don't map to any real screen, so a bad link never dumps the user on Home.
 */
export function NotFoundPage() {
  return (
    <div className="page">
      <div className="pagehead">
        <h1>Page not found</h1>
        <p className="muted">The page you're looking for doesn't exist or may have moved.</p>
      </div>
      <EmptyState
        icon="search"
        title="We couldn't find that page"
        text="Check the address or head back home to keep shopping."
        action={
          <button className="btn" onClick={() => navigate("home")}>
            Back to home
          </button>
        }
      />
    </div>
  );
}
