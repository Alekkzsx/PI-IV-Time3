// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { createHmac, randomBytes, randomInt, randomUUID, timingSafeEqual } from "node:crypto";
import type { Environment } from "../../../config/environment.js";
import { AuthError } from "../../../shared/auth-error.js";
import type {
  AccessTokenIssuer,
  AuthProfile,
  AuthSecurityRepository,
  AuthUserRepository,
  PasswordHasher,
  RecoveryCodeRepository,
  RecoveryEmailSender,
} from "../domain/auth.types.js";

export interface AuthServiceDependencies {
  users: AuthUserRepository;
  security: AuthSecurityRepository;
  recoveryCodes: RecoveryCodeRepository;
  passwords: PasswordHasher;
  accessTokens: AccessTokenIssuer;
  recoveryEmail: RecoveryEmailSender;
  dummyPasswordHash: string;
  environment: Pick<
    Environment,
    "jwtSecret" | "otpSecret" | "otpTtlSeconds" | "otpMaxAttempts" | "jwtTtl"
  >;
}

/** Orquestra login, emissão de OTP e redefinição segura de senha. */
export class AuthService {
  constructor(private readonly dependencies: AuthServiceDependencies) {}

  ensureEmailAvailable(): void { this.dependencies.recoveryEmail.ensureAvailable?.(); }

  async login(input: {
    identity: string;
    password: string;
    profile: AuthProfile;
  }): Promise<{ accessToken: string; tokenType: "Bearer" } | { requiresTwoFactor: true; challengeToken: string }> {
    const user = await this.dependencies.users.findByIdentity(input.identity);
    const identity = user?.normalizedIdentity ?? normalizeIdentity(input.identity);
    await this.dependencies.security.assertLoginAllowed(identity);
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
      await this.dependencies.security.recordLoginFailure(identity);
      throw new AuthError(401, "invalid_credentials", "Credenciais inválidas.");
    }

    await this.dependencies.security.clearLoginFailures(identity);
    if (user.twoFactorRequired) {
      this.dependencies.recoveryEmail.ensureAvailable?.();
      const challengeToken = randomBytes(32).toString("base64url");
      const code = String(randomInt(100_000, 1_000_000));
      await this.dependencies.security.saveChallenge(user, this.digest(challengeToken), this.digest(code), new Date(Date.now() + 300_000));
      await this.dependencies.recoveryEmail.sendRecoveryCode({ to: user.email, displayName: user.displayName,
        code, expiresInSeconds: 300, purpose: "login" });
      return { requiresTwoFactor: true, challengeToken };
    }
    return this.createSession(user);
  }

  async verifyTwoFactor(challengeToken: string, code: string): Promise<{ accessToken: string; tokenType: "Bearer" }> {
    const user = await this.dependencies.security.consumeChallenge(this.digest(challengeToken), this.digest(code), new Date());
    if (!user) throw new AuthError(400, "invalid_two_factor_code", "Código inválido, expirado ou limite de tentativas excedido.");
    return this.createSession(user);
  }

  private async createSession(user: import("../domain/auth.types.js").AuthUser): Promise<{ accessToken: string; tokenType: "Bearer" }> {
    const sessionId = randomUUID();
    const ttl = this.dependencies.environment.jwtTtl;
    const seconds = Number(ttl.slice(0, -1)) * ({ s: 1, m: 60, h: 3600, d: 86400 }[ttl.slice(-1)] ?? 0);
    const accessToken = this.dependencies.accessTokens.issue(user, sessionId);
    await this.dependencies.security.saveSession(user, sessionId, new Date(Date.now() + seconds * 1000));
    return {
      accessToken,
      tokenType: "Bearer",
    };
  }

  async requestRecoveryCode(identity: string): Promise<number> {
    this.dependencies.recoveryEmail.ensureAvailable?.();
    const user = await this.dependencies.users.findByIdentity(identity);
    const normalizedIdentity = user?.normalizedIdentity ?? normalizeIdentity(identity);

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
      await this.dependencies.recoveryCodes.delete(normalizedIdentity, this.digest(code));
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
    const recovery = await this.dependencies.recoveryCodes.find(
      normalizedIdentity,
    );

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

    if (!this.matchesDigest(input.code, recovery.codeDigest)) {
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
    const resetTokenDigest = this.digest(resetToken);
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
    const consumed = await this.dependencies.recoveryCodes.resetPassword(
      normalizedIdentity,
      user.id,
      this.digest(input.resetToken),
      passwordHash,
      new Date(),
    );
    if (!consumed) {
      throw new AuthError(400, "invalid_reset_grant", "Solicitação inválida ou expirada.");
    }

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
