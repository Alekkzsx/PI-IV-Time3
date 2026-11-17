import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  buildDirectMongoUri,
  isDnsSrvFailure,
  parseDohJsonAnswers,
} from "../../shared/mongo/dns-fallback.js";

describe("MongoDB DNS/DoH fallback para redes corporativas", () => {
  it("identifica erros típicos de bloqueio DNS SRV em Wi-Fi corporativo/universidade", () => {
    assert.equal(isDnsSrvFailure(Object.assign(new Error("querySrv ECONNREFUSED"), { code: "ECONNREFUSED" })), true);
    assert.equal(isDnsSrvFailure(new Error("queryTxt ETIMEOUT cluster0.example.mongodb.net")), true);
    assert.equal(isDnsSrvFailure(new Error("Authentication failed")), false);
  });

  it("extrai registros SRV e TXT de respostas DNS-over-HTTPS (DoH)", () => {
    const srvPayload = {
      Status: 0,
      Answer: [
        { type: 33, data: "0 0 27017 ac-shard-00.example.mongodb.net." },
        { type: 33, data: "0 0 27017 ac-shard-01.example.mongodb.net." },
      ],
    };
    const txtPayload = {
      Status: 0,
      Answer: [
        { type: 16, data: "\"authSource=admin\" \"&replicaSet=atlas-1\"" },
      ],
    };
    assert.deepEqual(parseDohJsonAnswers(srvPayload, 33), [
      "0 0 27017 ac-shard-00.example.mongodb.net.",
      "0 0 27017 ac-shard-01.example.mongodb.net.",
    ]);
    assert.deepEqual(parseDohJsonAnswers(txtPayload, 16), [
      "authSource=admin&replicaSet=atlas-1",
    ]);
  });

  it("converte URI mongodb+srv em mongodb:// direta preservando credenciais e opções", () => {
    const direct = buildDirectMongoUri(
      "mongodb+srv://user:pass@cluster0.example.mongodb.net/agmrm?retryWrites=true&w=majority",
      [
        "0 0 27017 ac-shard-00.example.mongodb.net.",
        "0 0 27017 ac-shard-01.example.mongodb.net.",
      ],
      ["authSource=admin&replicaSet=atlas-1"],
    );
    assert.ok(direct.startsWith("mongodb://user:pass@ac-shard-00.example.mongodb.net:27017,ac-shard-01.example.mongodb.net:27017/agmrm?"));
    assert.ok(direct.includes("authSource=admin"));
    assert.ok(direct.includes("replicaSet=atlas-1"));
    assert.ok(direct.includes("retryWrites=true"));
    assert.ok(direct.includes("ssl=true"));
  });
});
