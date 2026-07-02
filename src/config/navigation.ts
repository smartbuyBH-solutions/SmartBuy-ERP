type NavigationItemBase = Readonly<{
  id: string;
  label: string;
  shortLabel: string;
}>;

type AvailableNavigationItem = NavigationItemBase &
  Readonly<{
    availability: "available";
    href: string;
  }>;

type PlannedNavigationItem = NavigationItemBase &
  Readonly<{
    availability: "planned";
    href: null;
  }>;

export type NavigationItem = AvailableNavigationItem | PlannedNavigationItem;

export const navigationItems = [
  {
    id: "overview",
    label: "Visão geral",
    shortLabel: "VG",
    availability: "available",
    href: "/",
  },
  {
    id: "lists",
    label: "Padronização de listas",
    shortLabel: "LS",
    availability: "planned",
    href: null,
  },
  {
    id: "services",
    label: "Atendimentos",
    shortLabel: "AT",
    availability: "planned",
    href: null,
  },
  {
    id: "quotes",
    label: "Orçamentos",
    shortLabel: "OR",
    availability: "planned",
    href: null,
  },
  {
    id: "upgrade",
    label: "Avaliação para upgrade",
    shortLabel: "UP",
    availability: "planned",
    href: null,
  },
  {
    id: "preowned",
    label: "Controle de seminovos",
    shortLabel: "SE",
    availability: "planned",
    href: null,
  },
  {
    id: "deliveries",
    label: "Confirmação de entrega",
    shortLabel: "EN",
    availability: "planned",
    href: null,
  },
  {
    id: "commercial-intelligence",
    label: "Inteligência comercial",
    shortLabel: "IC",
    availability: "planned",
    href: null,
  },
  {
    id: "technical-support",
    label: "Assistência técnica",
    shortLabel: "AS",
    availability: "planned",
    href: null,
  },
] as const satisfies readonly NavigationItem[];
