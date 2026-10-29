// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { createHmac, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import type { Environment } from "../../../config/environment.js";
import { AuthError } from "../../../shared/auth-error.js";
import type {
  AccessTokenIssuer,
  AuthProfile,
  AuthUserRepository,
  PasswordHasher,
  RecoveryCodeRepository,
  RecoveryEmailSender,
} from "../domain/auth.types.js";

export interface AuthServiceDependencies {
  users: AuthUserRepository;
  recoveryCodes: RecoveryCodeRepository;
  passwords: PasswordHasher;
  accessTokens: AccessTokenIssuer;
  recoveryEmail: RecoveryEmailSender;
  dummyPasswordHash: string;
  environment: Pick<
    Environment,
    "jwtSecret" | "otpSecret" | "otpTtlSeconds" | "otpMaxAttempts"
  >;
}

/** Orquestra login, emissão de OTP e redefinição segura de senha. */
export class AuthService {
  constructor(private readonly dependencies: AuthServiceDependencies) {}

  async login(input: {
    identity: string;
    password: string;
    profile: AuthProfile;
  }): Promise<{ accessToken: string; tokenType: "Bearer" }> {
    const user = await this.dependencies.users.findByIdentity(input.identity);
    const passwordMatches = await this.dependencies.passwords.verify(
      input.password,
      user?.passwordHash ?? this.dependencies.dummyPasswordHash,
    );

    if (
      !user ||
      !user.active ||
      user.profile !== input.profile ||
      !passwordMatches
    ) {
      throw new AuthError(401, "invalid_credentials", "Credenciais inválidas.");
    }

    return {
      accessToken: this.dependencies.accessTokens.issue(user),
      tokenType: "Bearer",
    };
  }

  async requestRecoveryCode(identity: string): Promise<number> {
    const normalizedIdentity = normalizeIdentity(identity);
    const user = await this.dependencies.users.findByIdentity(identity);

    // Resposta indistinguível para contas inexistentes evita enumeração de usuários.
    if (!user || !user.active) {
      return this.dependencies.environment.otpTtlSeconds;
    }

    const code = String(randomInt(100_000, 1_000_000));
    const expiresAt = new Date(
      Date.now() + this.dependencies.environment.otpTtlSeconds * 1000,
    );

    await this.dependencies.recoveryCodes.save({
      normalizedIdentity,
      codeDigest: this.digest(code),
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
      await this.dependencies.recoveryCodes.delete(normalizedIdentity);
      throw error;
    }
    return this.dependencies.environment.otpTtlSeconds;
  }

  async verifyRecoveryCode(input: {
    identity: string;
    code: string;
  }): Promise<{ valid: true; resetToken: string }> {
    const normalizedIdentity = normalizeIdentity(input.identity);
    const recovery = await this.dependencies.recoveryCodes.find(
      normalizedIdentity,
    );

    if (
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

    if (!this.matchesDigest(input.code, recovery.codeDigest)) {
      const attempts = await this.dependencies.recoveryCodes.incrementFailedAttempts(
        normalizedIdentity,
        this.dependencies.environment.otpMaxAttempts,
      );
      if (attempts === null || attempts >= this.dependencies.environment.otpMaxAttempts) {
        await this.dependencies.recoveryCodes.delete(normalizedIdentity);
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
    const resetTokenDigest = this.digest(resetToken);
    const grantExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await this.dependencies.recoveryCodes.issueResetGrant(
      normalizedIdentity,
      resetTokenDigest,
      grantExpiresAt,
    );

    return { valid: true, resetToken };
  }

  async resetPassword(input: {
    identity: string;
    resetToken: string;
    newPassword: string;
  }): Promise<void> {
    const normalizedIdentity = normalizeIdentity(input.identity);
    const user = await this.dependencies.users.findByIdentity(input.identity);
    if (!user || !user.active) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

    const recovery = await this.dependencies.recoveryCodes.find(
      normalizedIdentity,
    );
    if (
      !recovery?.verified ||
      !recovery.resetTokenDigest ||
      recovery.expiresAt.getTime() <= Date.now() ||
      !this.matchesDigest(input.resetToken, recovery.resetTokenDigest)
    ) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

    const passwordHash = await this.dependencies.passwords.hash(
      input.newPassword,
    );
    const consumed = await this.dependencies.recoveryCodes.consumeResetGrant(
      normalizedIdentity,
      this.digest(input.resetToken),
      new Date(),
    );
    if (!consumed) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

    await this.dependencies.users.updatePassword(
      user.id,
      passwordHash,
    );
  }

  private digest(value: string): string {
    return createHmac("sha256", this.dependencies.environment.otpSecret)
      .update(value)
      .digest("hex");
  }

  private matchesDigest(value: string, expectedDigest: string): boolean {
    const actual = Buffer.from(this.digest(value), "hex");
    const expected = Buffer.from(expectedDigest, "hex");
    return (
      actual.length === expected.length && timingSafeEqual(actual, expected)
    );
  }
}

export function normalizeIdentity(identity: string): string {
  return identity.trim().toLowerCase();
}
