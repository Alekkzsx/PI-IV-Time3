// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { loadEnvironment } from "./environment.js";

const minimalEnvironment: NodeJS.ProcessEnv = {
  NODE_ENV: "test",
  MONGODB_URI: "mongodb://127.0.0.1:27017",
  MONGODB_DATABASE: "auth_test",
  AUTH_JWT_SECRET: "f856909c412f62286daac9634c8c34880c1b5a2711112880204bdd426927477a",
  AUTH_OTP_SECRET: "g856909c412f62286daac9634c8c34880c1b5a2711112880204bdd426927477a",
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
