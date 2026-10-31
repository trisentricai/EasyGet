import { createContext, useContext, type ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  errText,
  getPlatformStorefront,
  type StorefrontPayload,
} from "../services/api";

type Ctx = {
  data: StorefrontPayload | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
};

const StorefrontContext = createContext<Ctx>({
  data: null,
  loading: true,
  error: null,
  reload: () => {},
});

/**
 * Platform storefront via React Query: cached client-side (staleTime 5 min)
 * so navigating back to the homepage never refetches, deduped across all
 * consumers, with a manual `reload()` escape hatch.
 */
export function StorefrontProvider({ children }: { children: ReactNode }) {
  const query = useQuery({
    queryKey: ["storefront", "platform"],
    queryFn: getPlatformStorefront,
    staleTime: 5 * 60_000,
    retry: 1,
  });

  const value: Ctx = {
    data: query.data ?? null,
    loading: query.isLoading,
    error: query.error ? errText(query.error, "Storefront not available") : null,
    reload: () => void query.refetch(),
  };

  return (
    <StorefrontContext.Provider value={value}>
      {children}
    </StorefrontContext.Provider>
  );
}

export const useStorefront = () => useContext(StorefrontContext);
