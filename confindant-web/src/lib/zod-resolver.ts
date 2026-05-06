/* eslint-disable @typescript-eslint/no-explicit-any */
import { zodResolver } from "@hookform/resolvers/zod";
import type { FieldValues, Resolver } from "react-hook-form";

/**
 * Adapts zod's input/output asymmetry (z.coerce.* and .transform()) to RHF's
 * single-type Resolver expectation. Returns a resolver typed against the
 * schema's *output* shape (post-coerce), which is what handleSubmit sees.
 */
export function zResolver<T extends FieldValues>(schema: unknown): Resolver<T> {
  return zodResolver(schema as any) as unknown as Resolver<T>;
}
