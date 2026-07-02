"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { navigationItems } from "@/config/navigation";

import styles from "./AppShell.module.css";

export function AppNavigation() {
  const pathname = usePathname();

  return (
    <nav aria-label="Navegação principal" className={styles.navigation}>
      <p className={styles.navigationLabel}>Módulos</p>

      <ul className={styles.navigationList}>
        {navigationItems.map((item) => {
          const isAvailable = item.availability === "available";

          const isActive = isAvailable && pathname === item.href;

          const itemClassName = [styles.navigationItem, isActive ? styles.navigationItemActive : ""]
            .filter(Boolean)
            .join(" ");

          return (
            <li key={item.id}>
              {isAvailable ? (
                <Link
                  aria-current={isActive ? "page" : undefined}
                  className={itemClassName}
                  href={item.href}
                >
                  <span aria-hidden="true" className={styles.navigationGlyph}>
                    {item.shortLabel}
                  </span>

                  <span className={styles.navigationText}>{item.label}</span>
                </Link>
              ) : (
                <span
                  aria-disabled="true"
                  className={[itemClassName, styles.navigationItemDisabled].join(" ")}
                >
                  <span aria-hidden="true" className={styles.navigationGlyph}>
                    {item.shortLabel}
                  </span>

                  <span className={styles.navigationText}>{item.label}</span>

                  <span className={styles.navigationStatus}>Em breve</span>
                </span>
              )}
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
