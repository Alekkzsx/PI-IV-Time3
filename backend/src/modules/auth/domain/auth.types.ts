// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

export const authProfiles = ["aluno", "docente", "admin"] as const;
export type AuthProfile = (typeof authProfiles)[number];

/** Dados mínimos de uma conta que a camada de autenticação pode consumir. */
export interface AuthUser {
  id: string;
  identity: string;
  normalizedIdentity: string;
  email: string;
  displayName: string;
  profile: AuthProfile;
  passwordHash: string;
  active: boolean;
  sessionVersion?: number;
  twoFactorRequired?: boolean;
}

export interface RecoveryCode {
  normalizedIdentity: string;
  codeDigest: string | null;
  failedAttempts: number;
  expiresAt: Date;
  resetTokenDigest?: string;
  verified?: boolean;
}

/** Portas da camada de domínio para persistência e serviços externos. */
export interface AuthUserRepository {
  findByIdentity(identity: string): Promise<AuthUser | null>;
  updatePassword(userId: string, passwordHash: string): Promise<void>;
}

export interface RecoveryCodeRepository {
  save(recoveryCode: RecoveryCode): Promise<void>;
  find(normalizedIdentity: string): Promise<RecoveryCode | null>;
  incrementFailedAttempts(
    normalizedIdentity: string,
    maximumAttempts: number,
    expectedCodeDigest: string,
  ): Promise<number | null>;
  issueResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    expiresAt: Date,
    expectedCodeDigest: string,
    maximumAttempts: number,
  ): Promise<void>;
  consumeResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    now: Date,
  ): Promise<boolean>;
  delete(normalizedIdentity: string, expectedCodeDigest?: string): Promise<void>;
  resetPassword(identity: string, userId: string, digest: string, passwordHash: string, now: Date): Promise<boolean>;
}

export interface PasswordHasher {
  hash(password: string): Promise<string>;
  verify(password: string, passwordHash: string): Promise<boolean>;
}

export interface AccessTokenIssuer {
  issue(user: AuthUser, sessionId: string): string;
}

export interface AuthSecurityRepository {
  assertLoginAllowed(identity: string): Promise<void>;
  recordLoginFailure(identity: string): Promise<void>;
  clearLoginFailures(identity: string): Promise<void>;
  saveSession(user: AuthUser, sessionId: string, expiresAt: Date): Promise<void>;
  saveChallenge(user: AuthUser, tokenDigest: string, codeDigest: string, expiresAt: Date): Promise<void>;
  consumeChallenge(tokenDigest: string, codeDigest: string, now: Date): Promise<AuthUser | null>;
}

export interface RecoveryEmailSender {
  ensureAvailable?(): void;
  sendRecoveryCode(input: {
    to: string;
    displayName: string;
    code: string;
    expiresInSeconds: number;
    purpose?: "login" | "recovery";
  }): Promise<void>;
}
