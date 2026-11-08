// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';

/// Entidade de domínio imutável que representa um período letivo no Boletim Escolar Discente.
///
/// Agrupa o identificador do período/semestre (ex: "2026/1") e a listagem consolidada
/// de notas parciais, médias, frequências e status regimentais das disciplinas matriculadas.
@immutable
class BoletimPeriod {
  /// Identificador textual do semestre ou período letivo (ex: "2026/1", "2025/2").
  final String period;

  /// Coleção de registros de desempenho acadêmico das disciplinas vinculadas ao período.
  final List<Map<String, dynamic>> items;

  /// Cria uma nova instância imutável de [BoletimPeriod].
  ///
  /// Parâmetros:
  /// - [period]: Rótulo do semestre letivo de referência.
  /// - [items]: Lista de mapas estruturados com notas, faltas e situação de cada matéria.
  const BoletimPeriod({required this.period, required this.items});

  /// Desserializa um mapa JSON proveniente da API em uma instância íntegra de [BoletimPeriod].
  ///
  /// Parâmetros:
  /// - [json]: Mapa de chave-valor contendo os dados do período letivo.
  ///
  /// Executa:
  /// 1. Extração segura da chave `period` com fallback para string vazia.
  /// 2. Mapeamento defensivo da lista `items` convertendo entradas aninhadas para mapas tipados.
  ///
  /// Retorna a entidade [BoletimPeriod] populada e protegida contra nulos.
  factory BoletimPeriod.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return BoletimPeriod(
      period: json['period']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const [],
    );
  }

  /// Serializa a entidade atual em um mapa compatível com JSON.
  ///
  /// Retorna um mapa contendo [period] e a lista [items].
  Map<String, dynamic> toJson() => {
    'period': period,
    'items': items,
  };
}

/// Alias de tipo retrocompatível para garantir conformidade em asserções de testes existentes.
typedef StudentBoletimPeriod = BoletimPeriod;
