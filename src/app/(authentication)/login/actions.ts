"use server";

import { redirect } from "next/navigation";

import { createServerIdentityRuntime } from "@/lib/auth/server-client";
import { startSession } from "@/modules/session";

export type LoginActionState = Readonly<{
  message: string | null;
  status: "error" | "idle";
}>;

function errorState(message: string): LoginActionState {
  return {
    message,
    status: "error",
  };
}

export async function loginAction(
  previousState: LoginActionState,
  formData: FormData,
): Promise<LoginActionState> {
  void previousState;

  const emailEntry = formData.get("email");
  const passwordEntry = formData.get("password");

  if (typeof emailEntry !== "string" || typeof passwordEntry !== "string") {
    return errorState("Informe o e-mail e a senha.");
  }

  let identityRuntime: Awaited<ReturnType<typeof createServerIdentityRuntime>>;

  try {
    identityRuntime = await createServerIdentityRuntime();
  } catch {
    return errorState("O serviço de identidade está indisponível. Tente novamente.");
  }

  if (identityRuntime.status === "configuration-unavailable") {
    return errorState("O serviço de identidade está indisponível. Tente novamente.");
  }

  const result = await startSession({
    authenticator: identityRuntime.identityAuthenticator,
    email: emailEntry,
    password: passwordEntry,
  });

  if (result.status === "invalid-input") {
    return errorState("Informe o e-mail e a senha.");
  }

  if (result.status === "invalid-credentials") {
    return errorState("E-mail ou senha inválidos.");
  }

  if (result.status === "service-unavailable") {
    return errorState("O serviço de identidade está indisponível. Tente novamente.");
  }

  redirect("/");
}
