// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { AuthService } from "./auth.service.js";
import type {
  AccessTokenIssuer,
  AuthUser,
  AuthUserRepository,
  PasswordHasher,
  RecoveryCode,
  RecoveryCodeRepository,
  RecoveryEmailSender,
} from "../domain/auth.types.js";
import { AuthError } from "../../../shared/auth-error.js";

class FakeUsers implements AuthUserRepository {
  readonly user: AuthUser = {
    id: "user-1",
    identity: "2024.1.00001",
    normalizedIdentity: "2024.1.00001",
    email: "student@example.edu",
    displayName: "Estudante",
    profile: "aluno",
    passwordHash: "hashed:correct-password",
    active: true,
  };
  updatedPasswordHash?: string;

  async findByIdentity(identity: string): Promise<AuthUser | null> {
    return identity.trim().toLowerCase() === this.user.normalizedIdentity
      ? this.user
      : null;
  }

  async updatePassword(_userId: string, passwordHash: string): Promise<void> {
    this.updatedPasswordHash = passwordHash;
  }
}

class FakeRecoveryCodes implements RecoveryCodeRepository {
  entry?: RecoveryCode;

  async save(recoveryCode: RecoveryCode): Promise<void> {
    this.entry = recoveryCode;
  }

  async find(normalizedIdentity: string): Promise<RecoveryCode | null> {
    return this.entry?.normalizedIdentity === normalizedIdentity
      ? this.entry
      : null;
  }

  async incrementFailedAttempts(
    normalizedIdentity: string,
    maximumAttempts: number,
  ): Promise<number | null> {
    if (
      this.entry?.normalizedIdentity !== normalizedIdentity ||
      this.entry.failedAttempts >= maximumAttempts
    ) {
      return null;
    }
    this.entry.failedAttempts += 1;
    return this.entry.failedAttempts;
  }

  async issueResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    expiresAt: Date,
  ): Promise<void> {
    if (this.entry?.normalizedIdentity !== normalizedIdentity) {
      throw new Error("Missing recovery code");
    }
    this.entry.codeDigest = null;
    this.entry.resetTokenDigest = tokenDigest;
    this.entry.verified = true;
    this.entry.expiresAt = expiresAt;
  }

  async consumeResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    now: Date,
  ): Promise<boolean> {
    const isValid =
      this.entry?.normalizedIdentity === normalizedIdentity &&
      this.entry.resetTokenDigest === tokenDigest &&
      this.entry.verified === true &&
      this.entry.expiresAt > now;
    if (isValid) this.entry = undefined;
    return isValid;
  }

  async delete(normalizedIdentity: string): Promise<void> {
    if (this.entry?.normalizedIdentity === normalizedIdentity) {
      this.entry = undefined;
    }
  }
}

class FakePasswords implements PasswordHasher {
  async hash(password: string): Promise<string> {
    return `hashed:${password}`;
  }

  async verify(password: string, passwordHash: string): Promise<boolean> {
    return `hashed:${password}` === passwordHash;
  }
}

class FakeTokens implements AccessTokenIssuer {
  issue(user: AuthUser): string {
    return `token:${user.id}`;
  }
}

class FakeEmail implements RecoveryEmailSender {
  code?: string;

  async sendRecoveryCode(input: { code: string }): Promise<void> {
    this.code = input.code;
  }
}

function createFixture() {
  const users = new FakeUsers();
  const recoveryCodes = new FakeRecoveryCodes();
  const email = new FakeEmail();
  const service = new AuthService({
    users,
    recoveryCodes,
    passwords: new FakePasswords(),
    accessTokens: new FakeTokens(),
    recoveryEmail: email,
    dummyPasswordHash: "hashed:timing-decoy",
    environment: {
      jwtSecret: "a-secure-test-secret-with-at-least-32-characters",
      otpSecret: "a-different-secure-test-secret-with-at-least-32-chars",
      otpTtlSeconds: 300,
      otpMaxAttempts: 3,
    },
  });
  return { service, users, recoveryCodes, email };
}

describe("AuthService", () => {
  it("allows login only when credentials and profile match", async () => {
    const { service } = createFixture();

    assert.deepEqual(
      await service.login({
        identity: "2024.1.00001",
        password: "correct-password",
        profile: "aluno",
      }),
      { accessToken: "token:user-1", tokenType: "Bearer" },
    );

    await assert.rejects(
      service.login({
        identity: "2024.1.00001",
        password: "correct-password",
        profile: "admin",
      }),
      (error: unknown) =>
        error instanceof AuthError && error.code === "invalid_credentials",
    );
  });

  it("does not disclose unknown identities when requesting recovery", async () => {
    const { service, email, recoveryCodes } = createFixture();

    assert.equal(await service.requestRecoveryCode("unknown-id"), 300);
    assert.equal(email.code, undefined);
    assert.equal(recoveryCodes.entry, undefined);
  });

  it("verifies one-time recovery code and consumes the reset grant", async () => {
    const { service, email, users, recoveryCodes } = createFixture();

    await service.requestRecoveryCode("2024.1.00001");
    assert.match(email.code ?? "", /^\d{6}$/);

    const { resetToken } = await service.verifyRecoveryCode({
      identity: "2024.1.00001",
      code: email.code!,
    });
    await service.resetPassword({
      identity: "2024.1.00001",
      resetToken,
      newPassword: "new-password",
    });

    assert.equal(users.updatedPasswordHash, "hashed:new-password");
    assert.equal(recoveryCodes.entry, undefined);
    await assert.rejects(
      service.resetPassword({
        identity: "2024.1.00001",
        resetToken,
        newPassword: "another-password",
      }),
      (error: unknown) =>
        error instanceof AuthError && error.code === "invalid_reset_grant",
    );
  });

  it("revokes a recovery code after the configured failed attempts", async () => {
    const { service, email, recoveryCodes } = createFixture();
    await service.requestRecoveryCode("2024.1.00001");

    for (let attempt = 0; attempt < 3; attempt += 1) {
      await assert.rejects(
        service.verifyRecoveryCode({
          identity: "2024.1.00001",
          code: "000000",
        }),
        AuthError,
      );
    }

    assert.equal(recoveryCodes.entry, undefined);
    assert.match(email.code ?? "", /^\d{6}$/);
  });
});
