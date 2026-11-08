// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import type { Db } from "mongodb";
import type { BaseEmailInput, EmailDeliveryResult } from "../domain/notification.types.js";

export type OutboxRecord = BaseEmailInput & {
  id: string;
  provider: "outbox";
  code?: string;
  purpose?: string;
  errorTrail?: string[];
  createdAt: Date;
  expiresAt: Date;
};

/**
 * Provedor Local Outbox (Tier 3) com tolerância a falhas (Zero Crash).
 * Persiste mensagens em MongoDB (com TTL de 24h), mantém buffer em memória para testes
 * e exibe o código OTP no terminal para viabilizar desenvolvimento e testes offline.
 */
export class LocalOutboxEmailProvider {
  private static readonly memoryRingBuffer: OutboxRecord[] = [];
  private static readonly MAX_BUFFER_SIZE = 50;
  private indexesInitialized = false;

  constructor(private readonly database?: Db) {}

  /** Inicializa índice TTL no MongoDB para auto-limpeza em 24h */
  private async ensureTtlIndex(): Promise<void> {
    if (this.indexesInitialized || !this.database) return;
    try {
      await this.database.collection("email_outbox").createIndex(
        { expiresAt: 1 },
        { expireAfterSeconds: 0 },
      );
      this.indexesInitialized = true;
    } catch {
      // Ignora erro se índice já existir
    }
  }

  async save(
    input: BaseEmailInput,
    meta?: { code?: string; purpose?: string; errorTrail?: string[] },
  ): Promise<EmailDeliveryResult> {
    const startTime = Date.now();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24h
    const id = `outbox_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const record: OutboxRecord = {
      ...input,
      id,
      provider: "outbox",
      code: meta?.code,
      purpose: meta?.purpose,
      errorTrail: meta?.errorTrail,
      createdAt: now,
      expiresAt,
    };

    // 1. Armazena no Ring Buffer em Memória
    LocalOutboxEmailProvider.memoryRingBuffer.unshift(record);
    if (LocalOutboxEmailProvider.memoryRingBuffer.length > LocalOutboxEmailProvider.MAX_BUFFER_SIZE) {
      LocalOutboxEmailProvider.memoryRingBuffer.pop();
    }

    // 2. Persiste no MongoDB (se conectado)
    if (this.database) {
      void this.ensureTtlIndex();
      try {
        await this.database.collection("email_outbox").insertOne(record);
      } catch (err: any) {
        console.warn(`[local-outbox] Falha ao persistir no MongoDB: ${err?.message}`);
      }
    }

    // 3. Imprime Banner no Terminal para desenvolvedores/testes locais
    this.printTerminalVisualizer(record);

    return {
      success: true,
      provider: "outbox",
      messageId: id,
      latencyMs: Date.now() - startTime,
    };
  }

  private printTerminalVisualizer(record: OutboxRecord): void {
    const divider = "═".repeat(68);
    console.info(`\n┌${divider}┐`);
    console.info(`│ 📬 [OUTBOX LOCAL / RESILIÊNCIA ATIVA]                               │`);
    console.info(`│ Para:    ${record.to.padEnd(58)}│`);
    console.info(`│ Assunto: ${record.subject.padEnd(58)}│`);
    if (record.code) {
      console.info(`│                                                                    │`);
      console.info(`│   CÓDIGO DE VERIFICAÇÃO OTP:  [ ${record.code} ]                       │`);
      console.info(`│                                                                    │`);
    }
    if (record.errorTrail && record.errorTrail.length > 0) {
      console.info(`│ Failover executado devido a:                                       │`);
      for (const err of record.errorTrail) {
        console.info(`│ • ${err.substring(0, 64).padEnd(65)}│`);
      }
    }
    console.info(`└${divider}┘\n`);
  }

  /** Retorna as mensagens registradas no buffer (para testes automatizados) */
  static getSentEmails(): ReadonlyArray<OutboxRecord> {
    return [...this.memoryRingBuffer];
  }

  /** Retorna a última mensagem enviada */
  static getLastEmail(): OutboxRecord | undefined {
    return this.memoryRingBuffer[0];
  }

  /** Limpa o buffer de memória */
  static clear(): void {
    this.memoryRingBuffer.length = 0;
  }
}
