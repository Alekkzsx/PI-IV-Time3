package auth;

import com.mongodb.spi.dns.DnsClient;
import com.mongodb.spi.dns.DnsException;
import com.mongodb.spi.dns.DnsWithResponseCodeException;
import utils.ConfigEnv;
import utils.Json;

import javax.naming.NameNotFoundException;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.InitialDirContext;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Hashtable;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Resolvedor DNS resiliente para MongoDB SRV/TXT compativel com Wi-Fi corporativo e universitario.
 * Ordem de resolucao:
 * 1) JNDI DNS com servidores customizados (MONGODB_DNS_SERVERS) ou DNS do SO (timeout curto de 2s);
 * 2) Fallback automatico via DNS-over-HTTPS (DoH na porta 443) quando consultas SRV/UDP-53 sao bloqueadas.
 */
public class ResilientDnsClient implements DnsClient {
    private static final long CACHE_TTL_MS = 60_000L;
    private static final int DOH_CONNECT_TIMEOUT_MS = 3_500;
    private static final int DOH_READ_TIMEOUT_MS = 4_000;
    private static final String[] DOH_ENDPOINTS = new String[] {
            "https://dns.google/resolve",
            "https://cloudflare-dns.com/dns-query"
    };

    private static final class CacheEntry {
        final List<String> records;
        final long expiresAt;

        CacheEntry(List<String> records, long expiresAt) {
            this.records = records;
            this.expiresAt = expiresAt;
        }
    }

    private final ConcurrentHashMap<String, CacheEntry> cache = new ConcurrentHashMap<String, CacheEntry>();

    @Override
    public List<String> getResourceRecordData(String resourceName, String resourceType) throws DnsException {
        if (resourceName == null || resourceName.trim().isEmpty()
                || resourceType == null || resourceType.trim().isEmpty()) {
            return Collections.emptyList();
        }
        String name = resourceName.trim();
        String type = resourceType.trim().toUpperCase(Locale.ROOT);
        String cacheKey = type + ":" + name.toLowerCase(Locale.ROOT);

        CacheEntry cached = cache.get(cacheKey);
        long now = System.currentTimeMillis();
        if (cached != null && cached.expiresAt > now) {
            return cached.records;
        }

        DnsException jndiError = null;
        try {
            List<String> jndiResult = resolveViaJndi(name, type);
            if (!jndiResult.isEmpty() || !"SRV".equals(type)) {
                List<String> safe = Collections.unmodifiableList(jndiResult);
                cache.put(cacheKey, new CacheEntry(safe, now + CACHE_TTL_MS));
                return safe;
            }
        } catch (DnsException e) {
            jndiError = e;
        }

        try {
            List<String> dohResult = resolveViaDoh(name, type);
            if (!dohResult.isEmpty() || !"SRV".equals(type)) {
                List<String> safe = Collections.unmodifiableList(dohResult);
                cache.put(cacheKey, new CacheEntry(safe, now + CACHE_TTL_MS));
                return safe;
            }
            if (jndiError != null) {
                throw jndiError;
            }
            return Collections.emptyList();
        } catch (DnsException dohError) {
            throw jndiError != null ? dohError : dohError;
        }
    }

    protected List<String> resolveViaJndi(String name, String type) throws DnsException {
        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put("java.naming.factory.initial", "com.sun.jndi.dns.DnsContextFactory");
        env.put("com.sun.jndi.dns.timeout.initial", "2000");
        env.put("com.sun.jndi.dns.timeout.retries", "1");

        String dnsServers = ConfigEnv.obter("MONGODB_DNS_SERVERS", null);
        if (dnsServers != null && !dnsServers.trim().isEmpty()) {
            StringBuilder providerUrl = new StringBuilder();
            for (String server : dnsServers.split(",")) {
                String clean = server.trim();
                if (!clean.isEmpty()) {
                    if (providerUrl.length() > 0) providerUrl.append(' ');
                    providerUrl.append("dns://").append(clean);
                }
            }
            if (providerUrl.length() > 0) {
                env.put("java.naming.provider.url", providerUrl.toString());
            }
        }

        InitialDirContext ctx = null;
        try {
            ctx = new InitialDirContext(env);
            Attributes attrs = ctx.getAttributes(name, new String[] { type });
            Attribute attr = attrs != null ? attrs.get(type) : null;
            if (attr == null) {
                return Collections.emptyList();
            }
            List<String> result = new ArrayList<String>();
            NamingEnumeration<?> all = attr.getAll();
            while (all.hasMore()) {
                Object value = all.next();
                if (value instanceof String) {
                    result.add((String) value);
                }
            }
            return result;
        } catch (NameNotFoundException e) {
            throw new DnsWithResponseCodeException(e.getMessage(), 3, e);
        } catch (NamingException e) {
            throw new DnsException("Falha JNDI DNS para " + name + " (" + type + "): " + e.getMessage(), e);
        } finally {
            if (ctx != null) {
                try {
                    ctx.close();
                } catch (NamingException ignored) { }
            }
        }
    }

    protected List<String> resolveViaDoh(String name, String type) throws DnsException {
        DnsException ultimoErro = null;
        for (String endpoint : DOH_ENDPOINTS) {
            HttpURLConnection conn = null;
            try {
                String queryUrl = endpoint + "?name=" + urlEncode(name) + "&type=" + urlEncode(type);
                URL url = new URL(queryUrl);
                conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Accept", "application/dns-json");
                conn.setRequestProperty("User-Agent", "AGMRM-Server/1.0");
                conn.setConnectTimeout(DOH_CONNECT_TIMEOUT_MS);
                conn.setReadTimeout(DOH_READ_TIMEOUT_MS);

                int status = conn.getResponseCode();
                if (status < 200 || status >= 300) {
                    ultimoErro = new DnsException("DoH " + endpoint + " retornou HTTP " + status, null);
                    continue;
                }
                String body = readStream(conn.getInputStream());
                return parseDohResponse(body, type);
            } catch (DnsException e) {
                ultimoErro = e;
            } catch (Exception e) {
                ultimoErro = new DnsException("Falha ao consultar DoH (" + endpoint + "): " + e.getMessage(), e);
            } finally {
                if (conn != null) {
                    conn.disconnect();
                }
            }
        }
        throw ultimoErro != null ? ultimoErro : new DnsException("Nenhum resolvedor DoH disponivel para " + name, null);
    }

    /**
     * Analisa JSON de resposta DNS-over-HTTPS (Google/Cloudflare JSON API) no formato esperado pelo MongoDB Driver.
     */
    public static List<String> parseDohResponse(String jsonBody, String recordType) throws DnsException {
        if (jsonBody == null || jsonBody.trim().isEmpty()) {
            throw new DnsException("Resposta DoH vazia.", null);
        }
        final Map<String, Object> root;
        try {
            root = Json.analisarObjeto(jsonBody);
        } catch (IllegalArgumentException e) {
            throw new DnsException("JSON DoH invalido: " + e.getMessage(), e);
        }

        Object statusObj = root.get("Status");
        int dnsStatus = statusObj instanceof Number ? ((Number) statusObj).intValue() : 0;
        if (dnsStatus == 3) {
            throw new DnsWithResponseCodeException("NXDOMAIN via DoH", 3, null);
        }
        if (dnsStatus != 0) {
            throw new DnsException("DoH retornou Status DNS " + dnsStatus, null);
        }

        Object answerObj = root.get("Answer");
        if (!(answerObj instanceof List)) {
            return Collections.emptyList();
        }

        int expectedCode = "SRV".equalsIgnoreCase(recordType) ? 33
                : ("TXT".equalsIgnoreCase(recordType) ? 16 : -1);
        List<String> records = new ArrayList<String>();
        for (Object item : (List<?>) answerObj) {
            if (!(item instanceof Map)) continue;
            Map<?, ?> entry = (Map<?, ?>) item;
            Object rrType = entry.get("type");
            if (expectedCode != -1 && rrType instanceof Number && ((Number) rrType).intValue() != expectedCode) {
                continue;
            }
            Object dataObj = entry.get("data");
            if (!(dataObj instanceof String)) continue;
            String rawData = ((String) dataObj).trim();
            if (rawData.isEmpty()) continue;

            if ("TXT".equalsIgnoreCase(recordType)) {
                records.add(normalizarTxt(rawData));
            } else if ("SRV".equalsIgnoreCase(recordType)) {
                records.add(rawData.replaceAll("\\s+", " "));
            } else {
                records.add(rawData);
            }
        }
        return records;
    }

    private static String normalizarTxt(String raw) {
        String s = raw.trim();
        if (!s.contains("\"")) {
            return s;
        }
        StringBuilder out = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (inQuotes || !Character.isWhitespace(c)) {
                out.append(c);
            }
        }
        return out.toString();
    }

    private static String readStream(InputStream in) throws IOException {
        if (in == null) return "";
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[1024];
        int n;
        while ((n = in.read(buf)) != -1) {
            out.write(buf, 0, n);
        }
        return new String(out.toByteArray(), StandardCharsets.UTF_8);
    }

    private static String urlEncode(String val) {
        try {
            return URLEncoder.encode(val != null ? val : "", "UTF-8");
        } catch (UnsupportedEncodingException e) {
            return val != null ? val : "";
        }
    }
}
