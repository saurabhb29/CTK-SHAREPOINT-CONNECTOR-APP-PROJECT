public class Test4 {
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