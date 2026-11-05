type IconName = "download" | "upload" | "x";

interface IconProps {
  name: IconName;
  size?: number;
}

/** Minimal inline icon set used by the admin tables and toolbars. */
export function Icon({ name, size = 16 }: IconProps) {
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 2,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
  };

  if (name === "download") {
    return (
      <svg {...common}>
        <path d="M12 3v12" />
        <path d="m7 10 5 5 5-5" />
        <path d="M5 21h14" />
      </svg>
    );
  }

  if (name === "upload") {
    return (
      <svg {...common}>
        <path d="M12 21V9" />
        <path d="m7 14 5-5 5 5" />
        <path d="M5 3h14" />
      </svg>
    );
  }

  return (
    <svg {...common}>
      <path d="M18 6 6 18" />
      <path d="m6 6 12 12" />
    </svg>
  );
}
