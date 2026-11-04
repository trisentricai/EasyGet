/**
 * Static company / policy pages linked from the footer.
 *
 * A single content map keeps the copy in one place and gives every footer
 * link a real destination — no link should silently dump the shopper back
 * on the home page.
 */
import { PageCrumbs } from "../components/ui";
import { Icon, type IconName } from "../components/icons";
import { href } from "../hooks/useHashRoute";

type Block = {
  title: string;
  body: string;
  icon?: IconName;
};

type InfoContent = {
  title: string;
  intro: string;
  blocks: Block[];
};

const CONTENT: Record<string, InfoContent> = {
  about: {
    title: "About EasyGet",
    intro: "Everyday essentials, delivered with care — that is the whole idea.",
    blocks: [
      {
        title: "One store, every aisle",
        body: "Groceries, personal care, household basics and more, gathered from trusted local sellers so you can finish the weekly shop in one place.",
        icon: "store",
      },
      {
        title: "Prices you can plan around",
        body: "Clear pricing, honest discounts and no last-minute surprises. Delivery is free on orders above ₹499.",
        icon: "tag",
      },
      {
        title: "Delivery that respects your day",
        body: "Most orders arrive in 3–5 days, with cash on delivery available across our serviceable pincodes.",
        icon: "truck",
      },
    ],
  },
  contact: {
    title: "Contact us",
    intro: "Questions about an order, a product or a return? We are happy to help.",
    blocks: [
      {
        title: "Customer support",
        body: "Email support@easyget.app — we reply within one working day, usually much sooner.",
        icon: "edit",
      },
      {
        title: "Order help",
        body: "For the fastest answer, open Your Orders and choose the order in question so we can see the details straight away.",
        icon: "box",
      },
      {
        title: "Working hours",
        body: "Monday to Saturday, 9:00 am – 7:00 pm IST. Order tracking is available around the clock.",
        icon: "clock",
      },
    ],
  },
  careers: {
    title: "Careers at EasyGet",
    intro: "We are building a calmer, more dependable way to shop for everyday things.",
    blocks: [
      {
        title: "Operations & delivery",
        body: "Help us move orders quickly and carefully across the city, from picking to the front door.",
        icon: "truck",
      },
      {
        title: "Engineering & product",
        body: "Work on the storefront, seller tools and the systems that keep stock and delivery promises honest.",
        icon: "zap",
      },
      {
        title: "Category & seller success",
        body: "Bring great local sellers on board and help them present their products beautifully.",
        icon: "store",
      },
    ],
  },
  help: {
    title: "Help & FAQ",
    intro: "The quick answers to the questions we hear most often.",
    blocks: [
      {
        title: "Where is my order?",
        body: "Sign in and open Your Orders to see live status, the order timeline and the delivery address used.",
        icon: "box",
      },
      {
        title: "Can I change or cancel an order?",
        body: "Orders can be cancelled while they are still Pending, Confirmed or Preparing. Open the order and choose Cancel order.",
        icon: "refresh",
      },
      {
        title: "What payment methods do you accept?",
        body: "Cash on delivery is available, along with UPI and card options at checkout where supported.",
        icon: "wallet",
      },
      {
        title: "How do I return something?",
        body: "Most items can be returned within 7 days. Start from Your Orders or read the returns policy for the details.",
        icon: "shieldCheck",
      },
    ],
  },
  returns: {
    title: "Returns & refunds",
    intro: "If something is not right, we will make it right — within 7 days of delivery.",
    blocks: [
      {
        title: "7-day easy returns",
        body: "Most unopened, unused items can be returned within 7 days. Keep the packaging and tags where possible.",
        icon: "refresh",
      },
      {
        title: "How to start a return",
        body: "Open Your Orders, choose the item and select the return option. If you need a hand, contact support with the order number.",
        icon: "box",
      },
      {
        title: "Refunds",
        body: "Once the return is received and checked, refunds are issued to the original payment method. Cash-on-delivery orders are refunded via bank transfer.",
        icon: "wallet",
      },
    ],
  },
  terms: {
    title: "Terms of use",
    intro: "Plain-language terms for shopping with EasyGet.",
    blocks: [
      {
        title: "Using the service",
        body: "Use EasyGet for lawful personal shopping. Do not attempt to disrupt the service, scrape private data or abuse offers.",
        icon: "shieldCheck",
      },
      {
        title: "Orders and pricing",
        body: "Prices and availability are confirmed at checkout. If an item becomes unavailable after an order is placed, we will contact you about a replacement or refund.",
        icon: "receipt",
      },
      {
        title: "Accounts",
        body: "You are responsible for keeping your sign-in details private. Tell support immediately if you notice unusual account activity.",
        icon: "user",
      },
    ],
  },
  privacy: {
    title: "Privacy",
    intro: "We collect only what we need to take your order and get it to your door.",
    blocks: [
      {
        title: "What we collect",
        body: "Account details, delivery addresses, order history and basic device information used to keep the store working and secure.",
        icon: "info",
      },
      {
        title: "How we use it",
        body: "To process orders, provide support, prevent fraud and improve the shopping experience. We do not sell your personal data.",
        icon: "shieldCheck",
      },
      {
        title: "Your controls",
        body: "You can update saved addresses from your account and ask support to help with account or data requests.",
        icon: "user",
      },
    ],
  },
};

export function InfoPage({ page }: { page: string }) {
  const content = CONTENT[page] ?? CONTENT.help;

  return (
    <div className="page page-narrow info-page">
      <PageCrumbs current={content.title} />

      <header className="pagehead">
        <h1>{content.title}</h1>
        <p className="muted">{content.intro}</p>
      </header>

      <div className="info-grid">
        {content.blocks.map((block) => (
          <article className="info-card" key={block.title}>
            <span className="info-card-ico" aria-hidden="true">
              <Icon name={block.icon ?? "info"} size={19} />
            </span>
            <div>
              <h2>{block.title}</h2>
              <p>{block.body}</p>
            </div>
          </article>
        ))}
      </div>

      <div className="info-cta">
        <a className="btn btn-primary" href={href("browse")}>Start shopping</a>
        <a className="btn btn-ghost" href={href("contact")}>Contact support</a>
      </div>
    </div>
  );
}
