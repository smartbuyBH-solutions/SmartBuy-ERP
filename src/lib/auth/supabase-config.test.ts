import { describe, expect, it } from "vitest";

import { readServerAuthConfig, SERVER_AUTH_ENVIRONMENT_KEYS } from "./supabase-config";

describe("readServerAuthConfig", () => {
  it("returns normalized production configuration", () => {
    expect(
      readServerAuthConfig({
        [SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl]: "https://backend.example.test/",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey]: "sb_publishable_example",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]: "https://project.supabase.co/",
      }),
    ).toEqual({
      config: {
        backendApiUrl: "https://backend.example.test",
        supabasePublishableKey: "sb_publishable_example",
        supabaseUrl: "https://project.supabase.co",
      },
      status: "available",
    });
  });

  it("accepts loopback HTTP URLs for local development", () => {
    expect(
      readServerAuthConfig({
        [SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl]: "http://127.0.0.1:3001",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey]: "local-publishable-key",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]: "http://127.0.0.1:54321",
      }).status,
    ).toBe("available");
  });

  it("reports every missing or invalid key without exposing values", () => {
    expect(
      readServerAuthConfig({
        [SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl]: "ftp://backend.test",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey]: " ",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]: "not-a-url",
      }),
    ).toEqual({
      missingOrInvalidKeys: [
        "SMARTBUY_BACKEND_URL",
        "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
        "NEXT_PUBLIC_SUPABASE_URL",
      ],
      status: "unavailable",
    });
  });

  it("rejects a key marked as secret or administrative", () => {
    const secretLikeKey = ["sb", "secret", "test"].join("_");

    expect(
      readServerAuthConfig({
        [SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl]: "https://backend.example.test",
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey]: secretLikeKey,
        [SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]: "https://project.supabase.co",
      }),
    ).toEqual({
      missingOrInvalidKeys: ["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"],
      status: "unavailable",
    });
  });
});
