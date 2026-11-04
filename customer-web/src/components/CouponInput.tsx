import { useState, type FormEvent } from "react";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { couponLabel } from "../utils/coupon";
import { Icon } from "./icons";

/**
 * Reusable coupon field. Lives on the cart and the checkout review so a
 * shopper can apply/remove the same coupon in either place; the applied state
 * is owned by CartContext so both stay in sync.
 */
export function CouponInput({ id = "coupon-code" }: { id?: string }) {
  const { appliedCoupon, applyCoupon, removeCoupon, couponBusy } = useCart();
  const toast = useToast();
  const [code, setCode] = useState("");

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    const clean = code.trim();
    if (!clean) {
      toast.push("Enter a coupon code.", "err");
      return;
    }
    const result = await applyCoupon(clean);
    if (result.ok) {
      toast.push(`Coupon ${clean.toUpperCase()} applied`);
      setCode("");
    } else {
      toast.push(result.message ?? "This coupon can't be applied.", "err");
    }
  };

  if (appliedCoupon) {
    return (
      <div className="coupon-box coupon-applied">
        <span className="coupon-applied-ico" aria-hidden="true">
          <Icon name="tag" size={16} />
        </span>
        <div className="coupon-applied-copy">
          <b>{appliedCoupon.code}</b>
          <span>{couponLabel(appliedCoupon)} applied</span>
        </div>
        <button
          type="button"
          className="coupon-remove"
          aria-label={`Remove coupon ${appliedCoupon.code}`}
          title="Remove coupon"
          onClick={() => {
            removeCoupon();
            toast.push(`Coupon ${appliedCoupon.code} removed`, "info");
          }}
        >
          <Icon name="x" size={15} />
        </button>
      </div>
    );
  }

  return (
    <form className="coupon-box coupon-form" onSubmit={(e) => void submit(e)}>
      <label htmlFor={id} className="coupon-label">
        Have a coupon?
      </label>
      <div className="coupon-row">
        <input
          id={id}
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          placeholder="Enter coupon code"
          autoComplete="off"
          spellCheck={false}
        />
        <button className="btn btn-ghost btn-sm" type="submit" disabled={couponBusy}>
          {couponBusy ? "Applying…" : "Apply"}
        </button>
      </div>
    </form>
  );
}
