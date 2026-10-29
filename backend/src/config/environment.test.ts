// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { loadEnvironment } from "./environment.js";

const minimalEnvironment: NodeJS.ProcessEnv = {
  NODE_ENV: "test",
  MONGODB_URI: "mongodb://127.0.0.1:27017",
  MONGODB_DATABASE: "auth_test",
  AUTH_JWT_SECRET: "a-secure-test-secret-with-at-least-32-characters",
  AUTH_OTP_SECRET: "a-different-secure-test-secret-with-at-least-32-chars",
  SMTP_HOST: "",
  SMTP_USER: "",
  SMTP_PASSWORD: "",
  SMTP_FROM: "",
};

describe("loadEnvironment", () => {
  it("accepts empty SMTP variables as an unconfigured mail service", () => {
    const environment = loadEnvironment(minimalEnvironment);

    assert.equal(environment.smtp, undefined);
    assert.equal(environment.port, 3001);
    assert.equal(environment.otpTtlSeconds, 300);
  });

  it("rejects a shared OTP and JWT secret", () => {
    assert.throws(
      () =>
        loadEnvironment({
          ...minimalEnvironment,
          AUTH_OTP_SECRET: minimalEnvironment.AUTH_JWT_SECRET,
        }),
      /AUTH_JWT_SECRET e AUTH_OTP_SECRET devem ser diferentes/,
    );
  });

  it("rejects partial SMTP configuration instead of silently disabling mail", () => {
    assert.throws(
      () =>
        loadEnvironment({
          ...minimalEnvironment,
          SMTP_HOST: "smtp.example.edu",
        }),
      /Configure todos os campos SMTP/,
    );
  });
});
