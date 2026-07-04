import type { ReactNode } from "react";

import { AppShell } from "@/components/app-shell/AppShell";
import { SessionBoundaryState } from "@/components/session/SessionBoundaryState";
import { resolveCurrentServerSession } from "@/lib/auth/resolve-current-session";

export const dynamic = "force-dynamic";

type ErpLayoutProps = Readonly<{
  children: ReactNode;
}>;

export default async function ErpLayout({ children }: ErpLayoutProps) {
  const sessionResult = await resolveCurrentServerSession();

  if (sessionResult.status !== "authenticated") {
    return <SessionBoundaryState result={sessionResult} />;
  }

  return <AppShell session={sessionResult.session}>{children}</AppShell>;
}
