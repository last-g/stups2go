package org.zalando.stups.go.auth;

import com.thoughtworks.go.plugin.api.GoApplicationAccessor;
import com.thoughtworks.go.plugin.api.GoPlugin;
import com.thoughtworks.go.plugin.api.GoPluginIdentifier;
import com.thoughtworks.go.plugin.api.annotation.Extension;
import com.thoughtworks.go.plugin.api.logging.Logger;
import com.thoughtworks.go.plugin.api.request.GoPluginApiRequest;
import com.thoughtworks.go.plugin.api.response.GoPluginApiResponse;
import org.apache.http.client.fluent.Request;
import org.zalando.stups.tokens.AccessTokens;
import org.zalando.stups.tokens.Tokens;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static java.util.Arrays.asList;

@Extension
public class STUPSAuthenticationPlugin implements GoPlugin {
    private static final Logger LOGGER = Logger.getLoggerFor(STUPSAuthenticationPlugin.class);

    public static final String PLUGIN_ID = "stups.authenticator";
    public static final String EXTENSION_NAME = "authentication";
    private static final List<String> goSupportedVersions = asList("1.0");

    public static final String PLUGIN_AUTHENTICATION_CONFIGURATION = "go.authentication.plugin-configuration";
    public static final String SEARCH_USER = "go.authentication.search-user";
    public static final String AUTHENTICATE_USER = "go.authentication.authenticate-user";

    public static final int SUCCESS_RESPONSE_CODE = 200;
    public static final int INTERNAL_ERROR_RESPONSE_CODE = 500;

    private static final String ENV_ACCESS_TOKEN_URL = "STUPS_ACCESS_TOKEN_URL";
    private static final String ENV_TEAM_SERVICE_URL = "STUPS_TEAM_SERVICE_URL";
    private static final String ENV_TEAMS = "STUPS_TEAMS";

    private static final String TOKEN_SERVICE = "service";

    private AccessTokens tokens;

    @Override
    public GoPluginIdentifier pluginIdentifier() {
        System.out.println("STUPS Announcing plugin base information.");
        return new GoPluginIdentifier(EXTENSION_NAME, goSupportedVersions);
    }

    @Override
    public void initializeGoApplicationAccessor(final GoApplicationAccessor goApplicationAccessor) {
        // initialize background fetching of service token to get user list
        LOGGER.info("Initializing STUPS authentication plugin...");
        System.out.println("STUPS Initializing STUPS authentication plugin...");

        try {
            tokens = Tokens.createAccessTokensWithUri(new URI(System.getenv(ENV_ACCESS_TOKEN_URL) + "?realm=/services"))
                    .manageToken(TOKEN_SERVICE)
                    .addScope("uid")
                    .done()
                    .start();
        } catch (final URISyntaxException e) {
            throw new IllegalStateException(e);
        }
    }

    @Override
    public GoPluginApiResponse handle(final GoPluginApiRequest goPluginApiRequest) {
        System.out.println("STUPS Handling " + goPluginApiRequest.requestName());
        switch (goPluginApiRequest.requestName()) {
            case PLUGIN_AUTHENTICATION_CONFIGURATION:
                return handlePluginAuthenticationConfigurationRequest();
            case SEARCH_USER:
                return handleSearchUserRequest(goPluginApiRequest);
            case AUTHENTICATE_USER:
                return handleAuthenticateUserRequest(goPluginApiRequest);
            default:
                LOGGER.warn("Unknown request from server to me: " + goPluginApiRequest.requestName());
                System.out.println("STUPS Unknown request from server to me: " + goPluginApiRequest.requestName());
                return renderResponse(404, null, null);
        }
    }

    private GoPluginApiResponse handlePluginAuthenticationConfigurationRequest() {
        final Map<String, Object> configuration = new HashMap<>();
        configuration.put("display-name", "STUPS");
        configuration.put("supports-password-based-authentication", true);
        configuration.put("supports-user-search", true);
        return renderResponse(SUCCESS_RESPONSE_CODE, null, JSONUtils.toJSON(configuration));
    }

    private GoPluginApiResponse handleSearchUserRequest(GoPluginApiRequest goPluginApiRequest) {
        final Map<String, String> requestBodyMap = (Map<String, String>) JSONUtils.fromJSON(goPluginApiRequest.requestBody());
        final String searchTerm = requestBodyMap.get("search-term");

        final List<Map> searchResults = new ArrayList<>();
        final String[] teams = System.getenv(ENV_TEAMS).split(",");

        for (final String team: teams) {
            // ask team service
            final Map response;
            try {
                response = Request.Get(System.getenv(ENV_TEAM_SERVICE_URL) + "/teams/" + team)
                        .addHeader("Authorization", "Bearer " + tokens.get(TOKEN_SERVICE))
                        .execute()
                        .handleResponse(httpResponse -> {
                            final int status = httpResponse.getStatusLine().getStatusCode();
                            if (status != 200) {
                                throw new IllegalStateException("response status: " + status);
                            }
                            return (Map) JSONUtils.fromJSON(httpResponse.getEntity().getContent());
                        });
            } catch (final Exception e) {
                e.printStackTrace();
                continue;
            }

            final List<String> members = (List<String>) response.get("member");
            for (final String member : members) {
                if (member.contains(searchTerm)) {
                    searchResults.add(getUserJSON(member));
                }
            }
        }

        return renderResponse(SUCCESS_RESPONSE_CODE, null, JSONUtils.toJSON(searchResults));
    }

    private GoPluginApiResponse handleAuthenticateUserRequest(GoPluginApiRequest goPluginApiRequest) {
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSONUtils.fromJSON(goPluginApiRequest.requestBody());
        String username = (String) requestBodyMap.get("username");
        String password = (String) requestBodyMap.get("password");
        if (username.equals("test") && password.equals("test")) {
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("user", getUserJSON("test"));
            return renderResponse(SUCCESS_RESPONSE_CODE, null, JSONUtils.toJSON(userMap));
        } else {
            return renderResponse(SUCCESS_RESPONSE_CODE, null, null);
        }
    }

    private Map<String, String> getUserJSON(String username) {
        Map<String, String> userMap = new HashMap<>();
        userMap.put("username", username);
        return userMap;
    }


    private GoPluginApiResponse renderResponse(final int responseCode, final Map<String, String> responseHeaders, final String responseBody) {
        return new GoPluginApiResponse() {
            @Override
            public int responseCode() {
                return responseCode;
            }

            @Override
            public Map<String, String> responseHeaders() {
                return responseHeaders;
            }

            @Override
            public String responseBody() {
                return responseBody;
            }
        };
    }
}
