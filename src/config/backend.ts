export const BACKEND_CONTRACT_ID = "SBH-OPENAPI-001";
export const BACKEND_CONTRACT_SHA256 =
  "B2875EC60B0E4C3A3871EAEF15A9924F811F098FA7E49D1974341C9F9D4E7E2B";
export const BACKEND_URL_ENV_KEY = "SMARTBUY_BACKEND_URL";

export type BackendEnvironment = Readonly<Record<string, string | undefined>>;

function parseBackendOrigin(configuredValue: string): URL {
  let url: URL;

  try {
    url = new URL(configuredValue);
  } catch {
    throw new Error(`${BACKEND_URL_ENV_KEY} must be a valid absolute URL.`);
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error(`${BACKEND_URL_ENV_KEY} must use HTTP or HTTPS.`);
  }

  if (url.username || url.password || url.pathname !== "/" || url.search || url.hash) {
    throw new Error(`${BACKEND_URL_ENV_KEY} must contain only an HTTP(S) origin.`);
  }

  return url;
}

export function resolveBackendBaseUrl(environment: BackendEnvironment = process.env): string {
  const configuredValue = environment[BACKEND_URL_ENV_KEY]?.trim();

  if (!configuredValue) {
    throw new Error(`${BACKEND_URL_ENV_KEY} is required.`);
  }

  return parseBackendOrigin(configuredValue).origin;
}
