"use client";

import { useActionState } from "react";

import { loginAction, type LoginActionState } from "@/app/(authentication)/login/actions";

import styles from "./LoginForm.module.css";

const initialState: LoginActionState = {
  message: null,
  status: "idle",
};

export function LoginForm() {
  const [state, formAction, isPending] = useActionState(loginAction, initialState);

  return (
    <form action={formAction} className={styles.form}>
      <div className={styles.field}>
        <label className={styles.label} htmlFor="login-email">
          E-mail corporativo
        </label>

        <input
          autoComplete="username"
          className={styles.input}
          disabled={isPending}
          id="login-email"
          inputMode="email"
          name="email"
          required
          type="email"
        />
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="login-password">
          Senha
        </label>

        <input
          autoComplete="current-password"
          className={styles.input}
          disabled={isPending}
          id="login-password"
          name="password"
          required
          type="password"
        />
      </div>

      {state.status === "error" && state.message ? (
        <p className={styles.error} id="login-error" role="alert">
          {state.message}
        </p>
      ) : null}

      <button
        aria-describedby={state.status === "error" ? "login-error" : undefined}
        className={styles.action}
        disabled={isPending}
        type="submit"
      >
        {isPending ? "Validando sessão..." : "Entrar"}
      </button>
    </form>
  );
}
