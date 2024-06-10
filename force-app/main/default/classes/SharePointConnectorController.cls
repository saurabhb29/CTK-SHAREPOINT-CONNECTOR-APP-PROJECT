public class SharePointConnectorController {
    private static final String NAMED_CREDENTIAL = 'MyNamedCred';

    @AuraEnabled(cacheable=true)
    public static String getAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=client_credentials&scope=https://graph.microsoft.com/.default';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('HTTP Status (Access Token): ' + res.getStatus());
        System.debug('HTTP Response (Access Token): ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('access_token');
        } else {
            throw new AuthenticationException('Error authenticating to SharePoint: ' + res.getBody());
        }
    }

    public class AuthenticationException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSharePointData() {
        try {
            String accessToken = getAccessToken();
            String namedCredential = 'callout:SharePointNamedCredential';
            String relativeUrl = '/v1.0/sites/cynoteck.sharepoint.com,c9dee470-0a13-4670-882b-9764b2ea99aa,34774c41-d9c0-4be1-9dd6-6b24a35c22c5/lists/5a2e71dd-98be-4aa4-a5cb-44eb68742055/items?$expand=fields';
            String sharepointUrl = namedCredential + relativeUrl;
            System.debug('SharePoint Data URL: ' + sharepointUrl);

            String response = callout(sharepointUrl, 'GET', accessToken);
            System.debug('SharePoint Data Response: ' + response);

            // Parse the JSON response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            if (responseMap.containsKey('value')) {
                List<Object> rawItems = (List<Object>) responseMap.get('value');
                List<Map<String, Object>> items = new List<Map<String, Object>>();
                for (Object rawItem : rawItems) {
                    Map<String, Object> rawItemMap = (Map<String, Object>) rawItem;
                    Map<String, Object> fields = (Map<String, Object>) rawItemMap.get('fields');
                    Map<String, Object> item = new Map<String, Object>();
                    item.put('name', (String) fields.get('LinkFilename')); // Adjust field names as per SharePoint response
                    item.put('type', (String) fields.get('ContentType'));
                    item.put('modifiedBy', (String) fields.get('LastModifiedBy.User.DisplayName'));
                    item.put('modified', (String) fields.get('Modified'));

                    // Handle FileSizeDisplay field
                    // if (fields.get('FileSizeDisplay') != null) {
                    //     if (fields.get('FileSizeDisplay') instanceof Integer) {
                    //         item.put('fileSize', (Integer) fields.get('FileSizeDisplay'));
                    //     } else {
                    //         item.put('fileSize', Integer.valueOf((String) fields.get('FileSizeDisplay')));
                    //     }
                    // }

                    // Handle ItemChildCount field
                    if (fields.get('ItemChildCount') != null) {
                        if (fields.get('ItemChildCount') instanceof Integer) {
                            item.put('childCount', (Integer) fields.get('ItemChildCount'));
                        } else {
                            item.put('childCount', Integer.valueOf((String) fields.get('ItemChildCount')));
                        }
                    }

                    items.add(item);
                }
                System.debug('Parsed items: ' + items);
                return items;
            } else {
                throw new CalloutException('Unexpected response structure: ' + response);
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }

    private static String callout(String url, String method, String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('HTTP Status: ' + res.getStatus());
        System.debug('HTTP Response: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new CalloutException('Error during callout: ' + res.getStatus() + ' - ' + res.getBody());
        }
    }

    public class CalloutException extends Exception {}
}