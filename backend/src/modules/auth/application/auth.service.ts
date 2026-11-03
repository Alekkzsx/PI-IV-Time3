// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { randomBytes, randomInt, randomUUID } from "node:crypto";
import type { Environment } from "../../../config/environment.js";
import { AuthError } from "../../../shared/auth-error.js";
import { normalizeIdentity } from "../domain/identity.js";
import { PasswordRecoveryService } from "./password-recovery.service.js";
import { digestSecret } from "./secret-digest.js";
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
  private readonly passwordRecovery: PasswordRecoveryService;

  constructor(private readonly dependencies: AuthServiceDependencies) {
    this.passwordRecovery = new PasswordRecoveryService(dependencies);
  }

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
      await this.dependencies.security.saveChallenge(
        user,
        digestSecret(this.dependencies.environment.otpSecret, challengeToken),
        digestSecret(this.dependencies.environment.otpSecret, code),
        new Date(Date.now() + 300_000),
      );
      await this.dependencies.recoveryEmail.sendRecoveryCode({ to: user.email, displayName: user.displayName,
        code, expiresInSeconds: 300, purpose: "login" });
      return { requiresTwoFactor: true, challengeToken };
    }
    return this.createSession(user);
  }

  async verifyTwoFactor(challengeToken: string, code: string): Promise<{ accessToken: string; tokenType: "Bearer" }> {
    const user = await this.dependencies.security.consumeChallenge(
      digestSecret(this.dependencies.environment.otpSecret, challengeToken),
      digestSecret(this.dependencies.environment.otpSecret, code),
      new Date(),
    );
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
    return this.passwordRecovery.requestRecoveryCode(identity);
  }

  async verifyRecoveryCode(input: {
    identity: string;
    code: string;
  }): Promise<{ valid: true; resetToken: string }> {
    return this.passwordRecovery.verifyRecoveryCode(input);
  }

  async resetPassword(input: {
    identity: string;
    resetToken: string;
    newPassword: string;
  }): Promise<void> {
    return this.passwordRecovery.resetPassword(input);
  }

}

export { normalizeIdentity } from "../domain/identity.js";
