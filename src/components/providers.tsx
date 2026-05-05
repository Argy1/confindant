"use client";

import * as React from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "sonner";

export function Providers({ children }: { children: React.ReactNode }) {
  const [client] = React.useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            gcTime: 5 * 60_000,
            retry: (failureCount, err) => {
              const status = (err as { response?: { status?: number } })
                ?.response?.status;
              if (status === 401 || status === 403 || status === 404) return false;
              return failureCount < 2;
            },
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={client}>
      {children}
      <Toaster
        richColors
        position="top-right"
        closeButton
        toastOptions={{
          classNames: {
            toast:
              "rounded-xl border border-border bg-card text-foreground shadow-lg",
          },
        }}
      />
    </QueryClientProvider>
  );
}
