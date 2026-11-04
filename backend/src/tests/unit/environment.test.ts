// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { existsSync } from "node:fs";
import { loadEnvironment } from "../../config/environment.js";
import { resolveRootEnvPath, ROOT_ENV_PATH } from "../../config/local-environment.js";

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

  it("resolves JWT_SECRET as fallback for AUTH_JWT_SECRET", () => {
    const { AUTH_JWT_SECRET, ...withoutAuthSecret } = minimalEnvironment;
    const environment = loadEnvironment({
      ...withoutAuthSecret,
      JWT_SECRET: "f856909c412f62286daac9634c8c34880c1b5a2711112880204bdd426927477a",
    });
    assert.equal(environment.jwtSecret, "f856909c412f62286daac9634c8c34880c1b5a2711112880204bdd426927477a");
  });

  it("extracts pure email address from SMTP_FROM formatted with display name", () => {
    const environment = loadEnvironment({
      ...minimalEnvironment,
      SMTP_HOST: "smtp.example.com",
      SMTP_USER: "staff@example.com",
      SMTP_PASSWORD: "secret-password",
      SMTP_FROM: "Portal Academico <staff@example.com>",
    });
    assert.equal(environment.smtp?.from, "staff@example.com");
  });
});

describe("resolveRootEnvPath", () => {
  it("locates exclusively the master .env file at project root", () => {
    const resolved = resolveRootEnvPath();
    assert.ok(resolved.endsWith(".env"));
    assert.ok(existsSync(resolved), `O arquivo ${resolved} deve existir na raiz`);
    assert.equal(resolved, ROOT_ENV_PATH);
  });
});
