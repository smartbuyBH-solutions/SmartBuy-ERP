import { describe, expect, it } from "vitest";

import { navigationItems } from "./navigation";

describe("navigationItems", () => {
  it("keeps overview as the only available navigation item", () => {
    const availableItems = navigationItems.filter((item) => item.availability === "available");

    expect(availableItems).toHaveLength(1);
    expect(availableItems[0]).toMatchObject({
      id: "overview",
      label: "Visão geral",
      shortLabel: "VG",
      availability: "available",
      href: "/",
    });
  });

  it("keeps every planned item without a navigable route", () => {
    const plannedItems = navigationItems.filter((item) => item.availability === "planned");

    expect(plannedItems).toHaveLength(8);
    expect(plannedItems.every((item) => item.href === null)).toBe(true);
  });

  it("keeps identifiers and short labels unique in the canonical order", () => {
    const ids = navigationItems.map((item) => item.id);
    const shortLabels = navigationItems.map((item) => item.shortLabel);

    expect(new Set(ids).size).toBe(ids.length);
    expect(new Set(shortLabels).size).toBe(shortLabels.length);
    expect(ids).toEqual([
      "overview",
      "lists",
      "services",
      "quotes",
      "upgrade",
      "preowned",
      "deliveries",
      "commercial-intelligence",
      "technical-support",
    ]);
  });
});
