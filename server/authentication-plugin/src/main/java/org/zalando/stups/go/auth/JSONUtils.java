package org.zalando.stups.go.auth;

import com.google.gson.GsonBuilder;

import java.io.File;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;

public class JSONUtils {
    public static Object fromJSON(final String json) {
        return new GsonBuilder().create().fromJson(json, Object.class);
    }

    public static Object fromJSON(final InputStream json) {
        return new GsonBuilder().create().fromJson(new InputStreamReader(json), Object.class);
    }

    public static Object fromJSON(final File json) throws IOException {
        try (final FileReader reader = new FileReader(json)) {
            return new GsonBuilder().create().fromJson(reader, Object.class);
        }
    }

    public static String toJSON(final Object object) {
        return new GsonBuilder().create().toJson(object);
    }
}
