import { useState, type ImgHTMLAttributes, type ReactNode } from "react";

type SafeImageProps = Omit<ImgHTMLAttributes<HTMLImageElement>, "src" | "onError"> & {
  src?: string | null;
  /** Rendered when the URL is missing or the browser reports a load error. */
  fallback?: ReactNode;
  onError?: () => void;
};

/**
 * An <img> that can never show the browser's broken-image icon.
 *
 * Backend rows can legitimately carry dangling media paths (uploads on an
 * ephemeral disk, renamed files, old seeds). When the URL is absent or fails
 * to load we render the caller's existing placeholder instead — the gradient,
 * initials or monogram used everywhere else in the storefront.
 */
export function SafeImage({ src, fallback = null, onError, ...rest }: SafeImageProps) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  const failed = Boolean(src) && failedSrc === src;

  if (!src || failed) return <>{fallback}</>;

  return (
    <img
      {...rest}
      src={src}
      onError={() => {
        setFailedSrc(src);
        onError?.();
      }}
    />
  );
}
