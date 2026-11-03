import { randomBytes, randomInt } from "node:crypto";
import { AuthError } from "../../../shared/auth-error.js";
import type { AuthServiceDependencies } from "./auth.service.js";
import { matchesSecretDigest, digestSecret } from "./secret-digest.js";
import { normalizeIdentity } from "../domain/identity.js";

type RecoveryDependencies = Pick<
  AuthServiceDependencies,
  "users" | "recoveryCodes" | "passwords" | "recoveryEmail" | "environment"
>;

export class PasswordRecoveryService {
  constructor(private readonly dependencies: RecoveryDependencies) {}

  async requestRecoveryCode(identity: string): Promise<number> {
    this.dependencies.recoveryEmail.ensureAvailable?.();
    const user = await this.dependencies.users.findByIdentity(identity);
    const normalizedIdentity = user?.normalizedIdentity ?? normalizeIdentity(identity);

    if (!user || !user.active) {
      return this.dependencies.environment.otpTtlSeconds;
    }

    const code = String(randomInt(100_000, 1_000_000));
    const expiresAt = new Date(
      Date.now() + this.dependencies.environment.otpTtlSeconds * 1000,
    );

    await this.dependencies.recoveryCodes.save({
      normalizedIdentity,
      codeDigest: digestSecret(this.dependencies.environment.otpSecret, code),
      failedAttempts: 0,
      expiresAt,
    });

    try {
      await this.dependencies.recoveryEmail.sendRecoveryCode({
        to: user.email,
        displayName: user.displayName,
        code,
        expiresInSeconds: this.dependencies.environment.otpTtlSeconds,
      });
    } catch (error) {
      await this.dependencies.recoveryCodes.delete(
        normalizedIdentity,
        digestSecret(this.dependencies.environment.otpSecret, code),
      );
      throw error;
    }
    return this.dependencies.environment.otpTtlSeconds;
  }

  async verifyRecoveryCode(input: {
    identity: string;
    code: string;
  }): Promise<{ valid: true; resetToken: string }> {
    const user = await this.dependencies.users.findByIdentity(input.identity);
    const normalizedIdentity = user?.normalizedIdentity ?? normalizeIdentity(input.identity);
    const recovery = await this.dependencies.recoveryCodes.find(normalizedIdentity);

    if (
      !user?.active ||
      !recovery ||
      !recovery.codeDigest ||
      recovery.expiresAt.getTime() <= Date.now() ||
      recovery.failedAttempts >= this.dependencies.environment.otpMaxAttempts
    ) {
      throw new AuthError(
        400,
        "invalid_or_expired_code",
        "Código inválido ou expirado. Solicite um novo código.",
      );
    }

    if (!matchesSecretDigest(this.dependencies.environment.otpSecret, input.code, recovery.codeDigest)) {
      const attempts = await this.dependencies.recoveryCodes.incrementFailedAttempts(
        normalizedIdentity,
        this.dependencies.environment.otpMaxAttempts,
        recovery.codeDigest,
      );
      if (attempts === null || attempts >= this.dependencies.environment.otpMaxAttempts) {
        throw new AuthError(
          400,
          "recovery_attempts_exceeded",
          "Limite de tentativas excedido. Solicite um novo código.",
        );
      }
      throw new AuthError(
        400,
        "invalid_recovery_code",
        `Código incorreto. Restam ${this.dependencies.environment.otpMaxAttempts - attempts} tentativa(s).`,
      );
    }

    const resetToken = randomBytes(32).toString("base64url");
    const resetTokenDigest = digestSecret(this.dependencies.environment.otpSecret, resetToken);
    const grantExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await this.dependencies.recoveryCodes.issueResetGrant(
      normalizedIdentity,
      resetTokenDigest,
      grantExpiresAt,
      recovery.codeDigest,
      this.dependencies.environment.otpMaxAttempts,
    );

    return { valid: true, resetToken };
  }

  async resetPassword(input: {
    identity: string;
    resetToken: string;
    newPassword: string;
  }): Promise<void> {
    const user = await this.dependencies.users.findByIdentity(input.identity);
    const normalizedIdentity = user?.normalizedIdentity ?? normalizeIdentity(input.identity);
    if (!user || !user.active) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

    const recovery = await this.dependencies.recoveryCodes.find(normalizedIdentity);
    if (
      !recovery?.verified ||
      !recovery.resetTokenDigest ||
      recovery.expiresAt.getTime() <= Date.now() ||
      !matchesSecretDigest(this.dependencies.environment.otpSecret, input.resetToken, recovery.resetTokenDigest)
    ) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

    const passwordHash = await this.dependencies.passwords.hash(input.newPassword);
    const consumed = await this.dependencies.recoveryCodes.resetPassword(
      normalizedIdentity,
      user.id,
      digestSecret(this.dependencies.environment.otpSecret, input.resetToken),
      passwordHash,
      new Date(),
    );
    if (!consumed) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }
  }
}