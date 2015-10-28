package org.zalando.stups.go.auth;

import com.google.gson.GsonBuilder;

import java.io.InputStream;
import java.io.InputStreamReader;

public class JSONUtils {
    public static Object fromJSON(String json) {
        return new GsonBuilder().create().fromJson(json, Object.class);
    }

    public static Object fromJSON(InputStream json) {
        return new GsonBuilder().create().fromJson(new InputStreamReader(json), Object.class);
    }

    public static String toJSON(Object object) {
        return new GsonBuilder().create().toJson(object);
    }
}
