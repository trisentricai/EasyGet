import { useCallback, useEffect, useState } from "react";
import {
  deleteReview,
  errText,
  listReviews,
  updateReview,
  type AdminReview,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, ConfirmDialog, EmptyState, Spinner } from "../components/ui";

type Filter = "all" | "pending" | "approved";

function Stars({ n }: { n: number }) {
  return (
    <span title={`${n} of 5`} style={{ letterSpacing: 1, color: "#f5a623" }}>
      {"★".repeat(n)}
      <span style={{ color: "#d9d9d9" }}>{"★".repeat(5 - n)}</span>
    </span>
  );
}

export function ReviewsPage() {
  const { push } = useToast();
  const [reviews, setReviews] = useState<AdminReview[] | null>(null);
  const [filter, setFilter] = useState<Filter>("all");
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<AdminReview | null>(null);

  const load = useCallback(async () => {
    const res = await listReviews(
      filter === "pending" ? false : filter === "approved" ? true : undefined,
    );
    setReviews(Array.isArray(res) ? res : []);
  }, [filter]);

  useEffect(() => {
    setReviews(null);
    load().catch((e) => push(errText(e, "Failed to load reviews"), "err"));
  }, [load, push]);

  async function toggleApproved(r: AdminReview) {
    setBusy(true);
    try {
      await updateReview(r.id, { is_approved: !r.is_approved });
      push(r.is_approved ? "Review hidden from the storefront" : "Review approved");
      await load();
    } catch (e) {
      push(errText(e, "Update failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleting) return;
    setBusy(true);
    try {
      await deleteReview(deleting.id);
      push("Review deleted");
      setDeleting(null);
      await load();
    } catch (e) {
      push(errText(e, "Delete failed"), "err");
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <div className="toolbar">
        <div style={{ display: "flex", gap: 8 }}>
          {(["all", "pending", "approved"] as Filter[]).map((f) => (
            <button
              key={f}
              className={`btn btn-sm ${filter === f ? "btn-primary" : "btn-ghost"}`}
              onClick={() => setFilter(f)}
            >
              {f === "all" ? "All" : f === "pending" ? "Needs approval" : "Approved"}
            </button>
          ))}
        </div>
        <div className="spacer" />
        <span className="muted" style={{ fontSize: 13 }}>
          {reviews === null ? "" : `${reviews.length} review(s)`}
        </span>
      </div>

      <Card>
        {reviews === null ? (
          <Spinner />
        ) : reviews.length === 0 ? (
          <EmptyState text="No reviews match this filter." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Rating</th>
                  <th>Review</th>
                  <th>Reviewer</th>
                  <th>Status</th>
                  <th>Date</th>
                  <th style={{ width: 190 }} />
                </tr>
              </thead>
              <tbody>
                {reviews.map((r) => (
                  <tr key={r.id}>
                    <td style={{ fontWeight: 700 }}>{r.product_name}</td>
                    <td><Stars n={r.rating} /></td>
                    <td style={{ maxWidth: 320 }}>
                      {r.title ? <b>{r.title}: </b> : null}
                      <span className="muted">{r.body}</span>
                    </td>
                    <td>
                      {r.reviewer_name}
                      <div className="muted" style={{ fontSize: 12 }}>
                        {r.user_email}
                        {r.is_verified_purchase ? " · verified purchase" : ""}
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${r.is_approved ? "ok" : "err"}`}>
                        {r.is_approved ? "Live" : "Hidden"}
                      </span>
                    </td>
                    <td className="muted" style={{ whiteSpace: "nowrap" }}>
                      {new Date(r.created_at).toLocaleDateString()}
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                        <button
                          className="btn btn-sm btn-ghost"
                          disabled={busy}
                          onClick={() => void toggleApproved(r)}
                        >
                          {r.is_approved ? "Hide" : "Approve"}
                        </button>
                        <button
                          className="btn btn-sm btn-danger"
                          disabled={busy}
                          onClick={() => setDeleting(r)}
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {deleting && (
        <ConfirmDialog
          title={`Delete review by ${deleting.reviewer_name}?`}
          message="This permanently removes the review. This cannot be undone."
          onCancel={() => setDeleting(null)}
          onConfirm={confirmDelete}
          busy={busy}
        />
      )}
    </div>
  );
}
