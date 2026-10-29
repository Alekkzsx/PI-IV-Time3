// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import bcrypt from "bcryptjs";
import jwt, { type SignOptions } from "jsonwebtoken";
import type { Environment } from "../../../config/environment.js";
import type {
  AccessTokenIssuer,
  AuthUser,
  PasswordHasher,
} from "../domain/auth.types.js";

/** Usa bcrypt para armazenar senhas sem manter credenciais em texto claro. */
export class BcryptPasswordHasher implements PasswordHasher {
  private static readonly COST = 12;

  hash(password: string): Promise<string> {
    return bcrypt.hash(password, BcryptPasswordHasher.COST);
  }

  verify(password: string, passwordHash: string): Promise<boolean> {
    return bcrypt.compare(password, passwordHash);
  }
}

/** Emite JWT curto contendo somente identificador e perfil do usuário. */
export class JwtAccessTokenIssuer implements AccessTokenIssuer {
  constructor(
    private readonly secret: Environment["jwtSecret"],
    private readonly ttl: Environment["jwtTtl"],
  ) {}

  issue(user: AuthUser): string {
    return jwt.sign(
      { sub: user.id, profile: user.profile },
      this.secret,
      { expiresIn: this.ttl as SignOptions["expiresIn"] },
    );
  }
}
