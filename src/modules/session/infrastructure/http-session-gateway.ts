import type {
  OperatorSessionGateway,
  OperatorSessionGatewayInput,
} from "../application/session-ports";
import type { FetchOperatorSessionOptions, SessionFetch } from "./session-api";
import { fetchOperatorSession } from "./session-api";

export type CreateHttpOperatorSessionGatewayOptions = Readonly<{
  apiBaseUrl: string;
  fetchImpl?: SessionFetch;
}>;

export function createHttpOperatorSessionGateway({
  apiBaseUrl,
  fetchImpl,
}: CreateHttpOperatorSessionGatewayOptions): OperatorSessionGateway {
  return {
    async fetchSession({ accessToken, correlationId }: OperatorSessionGatewayInput) {
      const options: FetchOperatorSessionOptions = {
        accessToken,
        apiBaseUrl,
        ...(correlationId ? { correlationId } : {}),
        ...(fetchImpl ? { fetchImpl } : {}),
      };

      return fetchOperatorSession(options);
    },
  };
}
