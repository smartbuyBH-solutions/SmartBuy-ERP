export type OperatorSession = Readonly<{
  userId: string;
  displayName: string;
  role: string;
  capabilities: readonly string[];
}>;
