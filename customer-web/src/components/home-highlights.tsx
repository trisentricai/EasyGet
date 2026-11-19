import { href } from "../hooks/useHashRoute";
import { Icon, type IconName } from "./icons";

/**
 * Editorial brand blocks from the approved web concept. These are static
 * reassurance/wayfinding content only: no membership tier, price or checkout
 * state is invented, and every action points at an existing real route.
 */
const TRUST: { icon: IconName; title: string; text: string }[] = [
  {
    icon: "clock",
    title: "Quick, considered delivery",
    text: "Everyday essentials from nearby stores, chosen for the moment you need them.",
  },
  {
    icon: "shieldCheck",
    title: "Clear, honest pricing",
    text: "What you see is what you pay. Offers and charges stay visible at every step.",
  },
  {
    icon: "truck",
    title: "Easy returns",
    text: "Something not right? Our support team makes the next step simple.",
  },
];

const STEPS: { number: string; title: string; text: string }[] = [
  {
    number: "01",
    title: "Find your everyday",
    text: "Search by product or brand, or browse the aisles you already know.",
  },
  {
    number: "02",
    title: "Add to your bag",
    text: "See live prices and availability before you commit. No surprises.",
  },
  {
    number: "03",
    title: "Check out and relax",
    text: "Choose a slot, track your order and get it delivered to your door.",
  },
];

export function HomeHighlights() {
  return (
    <div className="home-highlights">
      <section className="trust-row" aria-label="Why EasyGet">
        {TRUST.map((item) => (
          <div className="trust-item" key={item.title}>
            <span className="trust-icon" aria-hidden="true">
              <Icon name={item.icon} size={20} />
            </span>
            <span>
              <strong>{item.title}</strong>
              <span>{item.text}</span>
            </span>
          </div>
        ))}
      </section>

      <section className="steps" aria-labelledby="how-it-works-title">
        <h2 id="how-it-works-title">Good things, made simple.</h2>
        <div className="step-grid">
          {STEPS.map((step) => (
            <article className="step-card" key={step.number}>
              <span className="step-number" aria-hidden="true">{step.number}</span>
              <h3>{step.title}</h3>
              <p>{step.text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="club-wrap" aria-label="Start shopping">
        <div className="club-banner">
          <div>
            <p className="hero-eyebrow">Everyday, sorted</p>
            <h2>Little essentials. Right when you need them.</h2>
            <p>
              Fresh food, bakery and household favourites from stores around you —
              in one calm, quick shopping experience.
            </p>
          </div>
          <a className="btn btn-secondary" href={href("browse")}>
            Explore the aisles <Icon name="arrowRight" size={17} />
          </a>
        </div>
      </section>
    </div>
  );
}
