public class Test20 {
    @AuraEnabled(cacheable=true)
    public static String getAuthorizationUrl() {
        SharePoint_Connector__mdt credentials = [SELECT Client_Id__c, Scope__c FROM SharePoint_Connector__mdt];
        
        String clientId = credentials.Client_Id__c;
        String redirectUri = 'https://cynotecktechnologysolutio-e-dev-ed.develop.lightning.force.com/lightning/n/SharePoint_Connector_App';
        String scope = 'api://0c4225d7-fbe3-4d1b-b8fd-e5905231e6b0/Files.Read';
        
        // Assuming 'callout:MyNamedCred' is your Named Credential for SharePoint
        String authEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
        
        String responseType = 'code';
        String state = 'someRandomState'; // You can generate a random state for CSRF protection
        
        String authUrl = authEndpoint 
                         + '?client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
                         + '&response_type=' + EncodingUtil.urlEncode(responseType, 'UTF-8')
                         + '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8')
                         + '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8')
                         + '&state=' + EncodingUtil.urlEncode(state, 'UTF-8');
        
        return authUrl;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccessToken(String authorizationCode) {
        String accessToken = null;
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse res;

        try {
            SharePoint_Connector__mdt credentials = [SELECT Client_Id__c, Client_Secret__c, Scope__c FROM SharePoint_Connector__mdt];

            String clientId = credentials.Client_Id__c;
            String clientSecret = credentials.Client_Secret__c;
            //String redirectUri = 'https://cynotecktechnologysolutio-e-dev-ed.develop.lightning.force.com/lightning/n/SharePoint_Connector_App';
            String scope = 'api://0c4225d7-fbe3-4d1b-b8fd-e5905231e6b0/Files.Read';

            req.setEndpoint('callout:MyNamedCred/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            String body = 'grant_type=authorization_code'
                        + '&code=' + EncodingUtil.urlEncode(authorizationCode, 'UTF-8')
                        + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
                        + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8')
                        // + '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8')
                        + '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8');
            req.setBody(body);

            res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                accessToken = (String) responseMap.get('access_token');
            } else {
                System.debug('Error: ' + res.getStatus() + ' ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }

        return accessToken;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllFoldersAndFiles(String accessToken) {
        // String accessToken = getAccessToken(String accessToken);
        if (accessToken == null) {
            throw new AuraHandledException('Failed to get access token');
        }

        String endpoint = 'callout:SharePointNamedCredential/_api/web/lists/GetByTitle(\'Documents\')/items?$expand=Folder,File,Editor&$select=Title,FileLeafRef,Modified,Editor/Title,File/Length,Folder/ItemCount';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> items = (List<Object>) responseBody.get('value');
            List<Map<String, Object>> result = new List<Map<String, Object>>();

            for (Object item : items) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                Map<String, Object> resultItem = new Map<String, Object>();

                resultItem.put('title', itemMap.get('Title'));
                resultItem.put('itemName', itemMap.get('FileLeafRef'));
                resultItem.put('modified', itemMap.get('Modified'));
                Map<String, Object> editor = (Map<String, Object>) itemMap.get('Editor');
                resultItem.put('modifiedBy', editor != null ? (String) editor.get('Title') : 'Unknown');

                if (itemMap.containsKey('Folder')) {
                    Map<String, Object> folder = (Map<String, Object>) itemMap.get('Folder');
                    resultItem.put('childCount', (folder != null && folder.get('ItemCount') != null) ? Integer.valueOf(folder.get('ItemCount').toString()) : 0);
                    resultItem.put('type', 'Folder');
                    resultItem.put('name', itemMap.get('Title'));
                    resultItem.put('icon', 'utility:folder');
                    resultItem.put('children', new List<Map<String, Object>>());
                } else if (itemMap.containsKey('File')) {
                    Map<String, Object> file = (Map<String, Object>) itemMap.get('File');
                    resultItem.put('fileSize', (file != null && file.get('Length') != null) ? Integer.valueOf(file.get('Length').toString()) : 0);
                    resultItem.put('type', 'File');
                    resultItem.put('name', itemMap.get('FileLeafRef'));
                    resultItem.put('icon', 'utility:file');
                    resultItem.put('children', null);
                }

                result.add(resultItem);
            }
            System.debug('Fetched items: ' + result);
            return result;
        } else {
            throw new AuraHandledException('Error from SharePoint: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
    
}