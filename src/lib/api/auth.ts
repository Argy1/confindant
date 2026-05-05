import { api, unwrap } from "./client";
import type { ApiEnvelope, LoginResponse, User } from "@/lib/types";

export const authApi = {
  async login(email: string, password: string) {
    const { data } = await api.post<ApiEnvelope<LoginResponse>>("/login", {
      email,
      password,
    });
    return unwrap(data);
  },
  async register(username: string, email: string, password: string) {
    const { data } = await api.post<ApiEnvelope<LoginResponse>>("/register", {
      username,
      email,
      password,
    });
    return unwrap(data);
  },
  async logout() {
    const { data } = await api.post<ApiEnvelope<null>>("/logout");
    return data;
  },
  async me() {
    const { data } = await api.get<ApiEnvelope<User>>("/user");
    return unwrap(data);
  },
};
