import { describe, expect, it } from "vitest";

import { navigationItems, selectNavigationItems, type NavigationItem } from "./navigation";

describe("navigationItems", () => {
  it("keeps overview as the only available navigation item", () => {
    const availableItems = navigationItems.filter((item) => item.availability === "available");

    expect(availableItems).toHaveLength(1);
    expect(availableItems[0]).toMatchObject({
      availability: "available",
      href: "/",
      id: "overview",
      label: "Visão geral",
      requiredCapabilities: [],
      shortLabel: "VG",
    });
  });

  it("keeps every planned item without a navigable route", () => {
    const plannedItems = navigationItems.filter((item) => item.availability === "planned");

    expect(plannedItems).toHaveLength(8);
    expect(plannedItems.every((item) => item.href === null)).toBe(true);
  });

  it("keeps identifiers and short labels unique in canonical order", () => {
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

describe("selectNavigationItems", () => {
  const controlledItems: readonly NavigationItem[] = [
    {
      availability: "available",
      href: "/",
      id: "overview",
      label: "Visão geral",
      requiredCapabilities: [],
      shortLabel: "VG",
    },
    {
      availability: "available",
      href: "/controlled",
      id: "controlled",
      label: "Área controlada",
      requiredCapabilities: ["controlled:read"],
      shortLabel: "AC",
    },
    {
      availability: "planned",
      href: null,
      id: "planned",
      label: "Planejado",
      shortLabel: "PL",
    },
  ];

  it("removes navigable destinations without the required capability", () => {
    expect(selectNavigationItems(controlledItems, []).map((item) => item.id)).toEqual([
      "overview",
      "planned",
    ]);
  });

  it("keeps the destination when every required capability is granted", () => {
    expect(
      selectNavigationItems(controlledItems, ["ignored:capability", " controlled:read "]).map(
        (item) => item.id,
      ),
    ).toEqual(["overview", "controlled", "planned"]);
  });
});
