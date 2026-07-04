"use server";

import { redirect } from "next/navigation";

import { createServerIdentityRuntime } from "@/lib/auth/server-client";
import { endSession } from "@/modules/session";

type LogoutActionState = Readonly<{
  status: "error" | "idle";
}>;

export async function logoutAction(
  previousState: LogoutActionState,
  formData: FormData,
): Promise<LogoutActionState> {
  void previousState;
  void formData;

  let identityRuntime: Awaited<ReturnType<typeof createServerIdentityRuntime>>;

  try {
    identityRuntime = await createServerIdentityRuntime();
  } catch {
    return {
      status: "error",
    };
  }

  if (identityRuntime.status === "configuration-unavailable") {
    return {
      status: "error",
    };
  }

  const result = await endSession({
    identityTerminator: identityRuntime.identityTerminator,
  });

  if (result.status === "service-unavailable") {
    return {
      status: "error",
    };
  }

  redirect("/");
}
