// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/** Erro controlado da camada de autenticação, com status e código públicos. */
export class AuthError extends Error {
  constructor(
    readonly statusCode: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "AuthError";
  }
}
