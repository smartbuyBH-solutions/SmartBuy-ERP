import { LoginForm } from "@/components/session/LoginForm";

import styles from "./page.module.css";

export const dynamic = "force-dynamic";

export default function LoginPage() {
  return (
    <main className={styles.viewport}>
      <section aria-labelledby="login-title" className={styles.card}>
        <span aria-hidden="true" className={styles.indicator} />

        <p className={styles.eyebrow}>Acesso ao ERP</p>

        <h1 className={styles.title} id="login-title">
          Revalidar sessão
        </h1>

        <p className={styles.description}>
          Informe suas credenciais corporativas para continuar. O acesso permanece bloqueado até a
          validação da identidade e das permissões.
        </p>

        <LoginForm />
      </section>
    </main>
  );
}
