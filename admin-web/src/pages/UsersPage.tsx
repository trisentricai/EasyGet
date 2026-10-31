import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createUser,
  errText,
  listUsers,
  updateUser,
  type ManagedUser,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, EmptyState, Modal, Spinner } from "../components/ui";

const ROLES = ["CUSTOMER", "MERCHANT", "DELIVERY_AGENT", "STORE_MANAGER", "ADMIN"];

type Draft = {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  role: string;
  is_active: boolean;
};

const emptyDraft: Draft = {
  email: "",
  password: "",
  first_name: "",
  last_name: "",
  role: "CUSTOMER",
  is_active: true,
};

function toArray<T>(res: { results: T[] } | T[]): T[] {
  return Array.isArray(res) ? res : res.results;
}

export function UsersPage() {
  const { push } = useToast();
  const queryClient = useQueryClient();
  const [query, setQuery] = useState("");
  const [editing, setEditing] = useState<ManagedUser | null>(null);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);

  const usersQuery = useQuery({
    queryKey: ["admin", "users"],
    queryFn: async () => toArray(await listUsers()),
  });
  const users = usersQuery.data ?? null;

  useEffect(() => {
    if (usersQuery.error)
      push(errText(usersQuery.error, "Failed to load users"), "err");
  }, [usersQuery.error, push]);

  function openCreate() {
    setDraft(emptyDraft);
    setCreating(true);
  }

  function openEdit(user: ManagedUser) {
    setEditing(user);
    setDraft({
      email: user.email,
      password: "",
      first_name: user.first_name ?? "",
      last_name: user.last_name ?? "",
      role: user.role,
      is_active: (user as { is_active?: boolean }).is_active ?? true,
    });
  }

  async function save() {
    if (!draft.email.trim()) return;
    if (creating && !draft.password) {
      push("Set an initial password (or have them sign in with Google).", "err");
      return;
    }
    setBusy(true);
    try {
      if (editing) {
        await updateUser(editing.id, { role: draft.role, is_active: draft.is_active });
        push(`Updated ${draft.email}`);
      } else {
        await createUser({
          email: draft.email.trim(),
          password: draft.password,
          first_name: draft.first_name.trim() || undefined,
          last_name: draft.last_name.trim() || undefined,
          role: draft.role,
        });
        push(`Created ${draft.email.trim()} as ${draft.role}`);
      }
      setCreating(false);
      setEditing(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    } catch (e) {
      push(errText(e, "Save failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  const filtered = (users ?? []).filter(
    (u) =>
      u.email.toLowerCase().includes(query.toLowerCase()) ||
      `${u.first_name} ${u.last_name}`.toLowerCase().includes(query.toLowerCase()),
  );

  return (
    <div>
      <div className="toolbar">
        <input
          className="input"
          placeholder="Search by email or name…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <div className="spacer" />
        <button className="btn btn-primary" onClick={openCreate}>
          + New user
        </button>
      </div>

      <Card>
        {users === null ? (
          <Spinner />
        ) : filtered.length === 0 ? (
          <EmptyState text="No users yet." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Email</th>
                  <th>Name</th>
                  <th>Role</th>
                  <th>Verified</th>
                  <th>Status</th>
                  <th style={{ width: 120 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((u) => (
                  <tr key={u.id}>
                    <td style={{ fontWeight: 700 }}>{u.email}</td>
                    <td>{`${u.first_name} ${u.last_name}`.trim() || "—"}</td>
                    <td>
                      <span className="badge">{u.role}</span>
                    </td>
                    <td>{u.is_email_verified ? "Yes" : "No"}</td>
                    <td>
                      <span className={`badge ${(u as { is_active?: boolean }).is_active ?? true ? "ok" : "err"}`}>
                        {(u as { is_active?: boolean }).is_active ?? true ? "Active" : "Disabled"}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-ghost" onClick={() => openEdit(u)}>
                          Edit
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

      {(creating || editing) && (
        <Modal
          title={editing ? `Edit ${editing.email}` : "New user"}
          subtitle="Admins can grant any role. New accounts start verified — no OTP email is sent."
          onClose={() => {
            setCreating(false);
            setEditing(null);
          }}
        >
          <div className="form-grid">
            <label>
              Email
              <input
                className="input"
                type="email"
                autoFocus
                disabled={!!editing}
                value={draft.email}
                onChange={(e) => setDraft({ ...draft, email: e.target.value })}
                placeholder="person@example.com"
              />
            </label>
            {creating && (
              <label>
                Initial password
                <input
                  className="input"
                  type="password"
                  value={draft.password}
                  onChange={(e) => setDraft({ ...draft, password: e.target.value })}
                  placeholder="At least 10 characters"
                />
              </label>
            )}
            <label>
              First name
              <input
                className="input"
                value={draft.first_name}
                onChange={(e) => setDraft({ ...draft, first_name: e.target.value })}
              />
            </label>
            <label>
              Last name
              <input
                className="input"
                value={draft.last_name}
                onChange={(e) => setDraft({ ...draft, last_name: e.target.value })}
              />
            </label>
            <label>
              Role
              <select
                className="input"
                value={draft.role}
                onChange={(e) => setDraft({ ...draft, role: e.target.value })}
              >
                {ROLES.map((r) => (
                  <option key={r} value={r}>
                    {r}
                  </option>
                ))}
              </select>
            </label>
            {editing && (
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={draft.is_active}
                  onChange={(e) => setDraft({ ...draft, is_active: e.target.checked })}
                />
                Active (disabled accounts cannot sign in)
              </label>
            )}
          </div>
          <div className="modal-actions">
            <button
              className="btn btn-ghost"
              onClick={() => {
                setCreating(false);
                setEditing(null);
              }}
              disabled={busy}
            >
              Cancel
            </button>
            <button
              className="btn btn-primary"
              onClick={save}
              disabled={busy || !draft.email.trim()}
            >
              {busy ? "Saving…" : "Save"}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
