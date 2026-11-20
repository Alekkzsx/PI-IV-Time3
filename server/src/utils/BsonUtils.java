// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package utils;

import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Utilitarios reutilizaveis de conversao entre documentos BSON do MongoDB
 * e mapas/listas Java padrao para serializacao JSON segura.
 */
public final class BsonUtils {
    private BsonUtils() {}

    /**
     * Converte recursivamente um Document BSON em Map Java, convertendo ObjectIds em hex string.
     */
    @SuppressWarnings("unchecked")
    public static Map<String, Object> documentoParaMapa(Object obj) {
        if (!(obj instanceof Document)) {
            return Collections.emptyMap();
        }
        Document doc = (Document) obj;
        Map<String, Object> mapa = new LinkedHashMap<String, Object>();
        for (Map.Entry<String, Object> entry : doc.entrySet()) {
            Object val = entry.getValue();
            if (val instanceof Document) {
                mapa.put(entry.getKey(), documentoParaMapa(val));
            } else if (val instanceof List) {
                mapa.put(entry.getKey(), converterLista((List<Object>) val));
            } else if (val instanceof ObjectId) {
                mapa.put(entry.getKey(), ((ObjectId) val).toHexString());
            } else {
                mapa.put(entry.getKey(), val);
            }
        }
        return mapa;
    }

    /**
     * Converte recursivamente um Map Java em Document BSON para persistencia no MongoDB.
     */
    @SuppressWarnings("unchecked")
    public static Document mapaParaDocumento(Map<String, Object> mapa) {
        Document doc = new Document();
        if (mapa == null) {
            return doc;
        }
        for (Map.Entry<String, Object> entry : mapa.entrySet()) {
            Object val = entry.getValue();
            if (val instanceof Map) {
                doc.append(entry.getKey(), mapaParaDocumento((Map<String, Object>) val));
            } else {
                doc.append(entry.getKey(), val);
            }
        }
        return doc;
    }

    private static List<Object> converterLista(List<Object> origem) {
        List<Object> convertida = new ArrayList<Object>(origem.size());
        for (Object item : origem) {
            if (item instanceof Document) {
                convertida.add(documentoParaMapa(item));
            } else if (item instanceof ObjectId) {
                convertida.add(((ObjectId) item).toHexString());
            } else {
                convertida.add(item);
            }
        }
        return convertida;
    }
}
