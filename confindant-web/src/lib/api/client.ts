"use client";

import axios, { AxiosError, type AxiosInstance } from "axios";
import { useAuthStore } from "@/store/auth";
import type { ApiEnvelope } from "@/lib/types";

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1";

export const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
  timeout: 30_000,
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers = config.headers ?? {};
    (config.headers as Record<string, string>).Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiEnvelope<unknown>>) => {
    if (error.response?.status === 401) {
      // Don't auto-logout on the login/register endpoints themselves
      const url = error.config?.url ?? "";
      if (!url.includes("/login") && !url.includes("/register")) {
        useAuthStore.getState().logout();
        if (typeof window !== "undefined") {
          const path = window.location.pathname;
          if (!path.startsWith("/login") && !path.startsWith("/register")) {
            window.location.href = "/login?expired=1";
          }
        }
      }
    }
    return Promise.reject(error);
  },
);

export function unwrap<T>(envelope: ApiEnvelope<T>): T {
  return envelope.data;
}

export function getApiErrorMessage(err: unknown, fallback = "Terjadi kesalahan"): string {
  if (axios.isAxiosError(err)) {
    const env = err.response?.data as ApiEnvelope<unknown> | undefined;
    if (env?.message) return env.message;
    if (env?.errors) {
      const first = Object.values(env.errors)[0];
      if (Array.isArray(first)) return first[0] ?? fallback;
      if (typeof first === "string") return first;
    }
    if (err.message) return err.message;
  }
  if (err instanceof Error) return err.message;
  return fallback;
}
