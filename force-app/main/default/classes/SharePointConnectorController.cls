public class SharePointConnectorController {
    private static final String NAMED_CREDENTIAL = 'MyNamedCred';
    @AuraEnabled(cacheable=true)
    public static String getAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=client_credentials' +
        '&scope=https://graph.microsoft.com/.default';
		//
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
    public static String getSharePointData() {
        try {
            // Get access token
            String accessToken = getAccessToken();

            // Construct SharePoint API URL using Named Credential
            String namedCredential = 'callout:SharePointNamedCredential'; // Replace with your Named Credential name
            String relativeUrl = '/v1.0/sites/cynoteck.sharepoint.com,c9dee470-0a13-4670-882b-9764b2ea99aa,34774c41-d9c0-4be1-9dd6-6b24a35c22c5/lists/5a2e71dd-98be-4aa4-a5cb-44eb68742055/items?$expand=fields';
          //  String sharepointUrl = 'https://graph.microsoft.com/v1.0/sites/cynoteck.sharepoint.com,c9dee470-0a13-4670-882b-9764b2ea99aa,34774c41-d9c0-4be1-9dd6-6b24a35c22c5/lists/5a2e71dd-98be-4aa4-a5cb-44eb68742055/items?$expand=fields';
			String sharepointUrl = namedCredential + relativeUrl;
            System.debug('SharePoint Data URL: ' + sharepointUrl);

            // Make the callout
            String response = callout(sharepointUrl, 'GET', accessToken);
            // Log the response
            System.debug('SharePoint Data Response: ' + response);
            return response;
        } catch (Exception e) {
            // Handle exceptions
            System.debug('Exception occurred: ' + e.getMessage());
            return null;
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