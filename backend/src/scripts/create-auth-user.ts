import "dotenv/config";
import { createInterface } from "node:readline/promises";
import { MongoClient } from "mongodb";
import { loadEnvironment } from "../config/environment.js";
import { BcryptPasswordHasher } from "../modules/auth/infrastructure/security.providers.js";
import { authProfiles, type AuthProfile } from "../modules/auth/domain/auth.types.js";

async function prompt(question: string): Promise<string> {
  const interfaceInstance = createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  try {
    return (await interfaceInstance.question(question)).trim();
  } finally {
    interfaceInstance.close();
  }
}

function promptPassword(question: string): Promise<string> {
  if (!process.stdin.isTTY || !process.stdout.isTTY) {
    throw new Error("Execute este comando em um terminal interativo.");
  }

  const input = process.stdin;
  const output = process.stdout;

  return new Promise((resolve, reject) => {
    let password = "";
    output.write(question);
    input.setRawMode(true);
    input.resume();

    const finish = (error?: Error): void => {
      input.setRawMode(false);
      input.pause();
      input.removeListener("data", handleData);
      output.write("\n");
      if (error) reject(error);
      else resolve(password);
    };

    const handleData = (chunk: Buffer): void => {
      for (const character of chunk.toString("utf8")) {
        if (character === "\u0003" || character === "\u0004") {
          finish(new Error("Cadastro cancelado."));
          return;
        }
        if (character === "\r" || character === "\n") {
          finish();
          return;
        }
        if (character === "\u007f" || character === "\b") {
          password = password.slice(0, -1);
          output.write("\b \b");
          continue;
        }
        if (character >= " ") {
          password += character;
          output.write("*");
        }
      }
    };

    input.on("data", handleData);
  });
}

async function main(): Promise<void> {
  const environment = loadEnvironment();
  const identity = await prompt("Identidade institucional: ");
  const email = await prompt("E-mail institucional: ");
  const displayName = await prompt("Nome de exibição: ");
  const profileInput = await prompt("Perfil (aluno/docente/admin): ");

  if (!identity || !email || !displayName) {
    console.error("Identidade, e-mail e nome são obrigatórios.");
    process.exitCode = 1;
    return;
  }
  if (!authProfiles.some((profile) => profile === profileInput)) {
    console.error("Perfil inválido. Use aluno, docente ou admin.");
    process.exitCode = 1;
    return;
  }

  const password = await promptPassword("Senha (mínimo 8 caracteres): ");
  const passwordConfirmation = await promptPassword("Confirme a senha: ");
  if (password.length < 8 || password.length > 128) {
    console.error("A senha deve ter entre 8 e 128 caracteres.");
    process.exitCode = 1;
    return;
  }
  if (password !== passwordConfirmation) {
    console.error("As senhas não conferem.");
    process.exitCode = 1;
    return;
  }

  const client = new MongoClient(environment.mongoUri, {
    serverSelectionTimeoutMS: 5_000,
  });

  try {
    await client.connect();
    const users = client.db(environment.mongoDatabase).collection("auth_users");
    const normalizedIdentity = identity.trim().toLowerCase();
    const existingUser = await users.findOne({ normalizedIdentity });
    if (existingUser) {
      console.error("Já existe uma conta com essa identidade.");
      process.exitCode = 1;
      return;
    }

    await users.createIndex({ normalizedIdentity: 1 }, { unique: true });
    const passwordHash = await new BcryptPasswordHasher().hash(password);
    await users.insertOne({
      identity: identity.trim(),
      normalizedIdentity,
      email: email.trim(),
      displayName: displayName.trim(),
      profile: profileInput as AuthProfile,
      passwordHash,
      active: true,
    });

    console.info("Conta criada em auth_users. Já pode testar o login no app.");
  } finally {
    await client.close();
  }
}

main().catch(() => {
  console.error(
    "Não foi possível criar a conta. Verifique a conexão, permissões e os dados informados.",
  );
  process.exitCode = 1;
});