public class SPIntegration {
    private static final String NAMED_CREDENTIAL = 'MyNamedCred';
    
    @AuraEnabled(cacheable=true)
    public static String getAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=client_credentials' +
        '&scope=https://graph.microsoft.com/.default';
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

    private static String getSiteId() {
        List<SharePoint_Connector__mdt> siteIdList = [SELECT SiteId__c FROM SharePoint_Connector__mdt WHERE SiteId__c != NULL LIMIT 1];
        if (!siteIdList.isEmpty()) {
            return siteIdList[0].SiteId__c;
        } else {
            throw new SiteIdNotFoundException('SiteId__c not found in SharePoint_Connector__mdt');
        }
    }

    private static String callout(String url, String method, String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('HTTP Status: ' + res.getStatus());
        System.debug('HTTP Response: ' + res.getBody());

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 204) {
            return res.getBody();
        } else {
            throw new CalloutException('Error during callout: ' + res.getStatus() + ' - ' + res.getBody());
        }
    }

    private static String callout(String url, String method, String accessToken, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('HTTP Status: ' + res.getStatus());
        System.debug('HTTP Response: ' + res.getBody());

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 204) {
            return res.getBody();
        } else {
            throw new CalloutException('Error during callout: ' + res.getStatus() + ' - ' + res.getBody());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getSharePointFolders() {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();

            String sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/root/children';
            System.debug('SharePoint Items URL: ' + sharepointUrl);

            String response = callout(sharepointUrl, 'GET', accessToken);
            System.debug('SharePoint Items Response: ' + response);
            return response;
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getSharePointFiles(String folderId) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();

            String sharepointUrl;
            if (folderId == null) {
                sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/root/children';
            } else {
                sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + folderId + '/children';
            }

            String response = callout(sharepointUrl, 'GET', accessToken);
            System.debug('SharePoint Files Response: ' + response);
            return response;
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static void createSharePointFolder(String parentId, String folderName) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();
            String sharepointUrl;

            if (parentId == null || parentId == 'root') {
                sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/root/children';
            } else {
                sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + parentId + '/children';
            }

            Map<String, Object> folderData = new Map<String, Object>();
            folderData.put('name', folderName);
            folderData.put('folder', new Map<String, Object>());
            folderData.put('@microsoft.graph.conflictBehavior', 'rename');

            String response = callout(sharepointUrl, 'POST', accessToken, JSON.serialize(folderData));
            System.debug('Create Folder Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception occurred while creating folder: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }

    @AuraEnabled
public static void uploadSharePointFile(String parentId, String fileName, String base64Data) {
    try {
        String accessToken = getAccessToken();
        String siteId = getSiteId();
        String encodedFileName = EncodingUtil.urlEncode(fileName, 'UTF-8');
        String sharepointUrl;

        if (parentId == null || parentId == 'root') {
            sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/root:/' + encodedFileName + ':/content';
        } else {
            sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + parentId + ':/' + encodedFileName + ':/content';
        }

        // Convert base64 to Blob
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(sharepointUrl);
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setHeader('Accept', 'application/json');
        req.setBodyAsBlob(fileBlob);

        // Detailed Debugging
        System.debug('Uploading to SharePoint URL: ' + sharepointUrl);
        System.debug('Request Headers: Authorization=' + req.getHeader('Authorization') + ', Content-Type=' + req.getHeader('Content-Type') + ', Accept=' + req.getHeader('Accept'));
        System.debug('Request Body Size: ' + fileBlob.size());

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('HTTP Status: ' + res.getStatus());
        System.debug('HTTP Response: ' + res.getBody());

        if (res.getStatusCode() != 201) {
            throw new CalloutException('Error uploading file: ' + res.getStatus() + ' - ' + res.getBody());
        }
    } catch (Exception e) {
        System.debug('Exception occurred while uploading file: ' + e.getMessage());
        throw new CalloutException('Error during callout: ' + e.getMessage());
    }
}



    // Method to rename a SharePoint item
    @AuraEnabled
    public static void renameSharePointItem(String itemId, String newName) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();
            String sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + itemId;

            Map<String, Object> renameData = new Map<String, Object>();
            renameData.put('name', newName);

            String response = callout(sharepointUrl, 'PATCH', accessToken, JSON.serialize(renameData));
            System.debug('Rename Item Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception occurred while renaming item: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }
    


    // Method to delete a SharePoint item
    @AuraEnabled
    public static void deleteSharePointItem(String itemId) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();
            String sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + itemId;
            System.debug('-----sharepointUrl---- ' + sharepointUrl);
            String response = callout(sharepointUrl, 'DELETE', accessToken);
            System.debug('Delete Item Response: ' + response);
        } catch (Exception e) {
            System.debug('Exception occurred while deleting item: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }

    // Method to get the preview URL of a SharePoint item
    @AuraEnabled
    public static String getSharePointItemPreviewUrl(String itemId) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();
            String sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + itemId + '/preview';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(sharepointUrl);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Length', '0');  // Add this header to specify content length

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('HTTP Status: ' + res.getStatus());
            System.debug('HTTP Response: ' + res.getBody());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 204) {
                return res.getBody();
            } else {
                throw new CalloutException('Error during callout: ' + res.getStatus() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred while getting preview URL: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }

    // Method to get the download URL of a SharePoint item
    @AuraEnabled
    public static String getSharePointItemDownloadUrl(String itemId) {
        try {
            String accessToken = getAccessToken();
            String siteId = getSiteId();
            String sharepointUrl = 'callout:SharePointNamedCredential/v1.0/sites/' + siteId + '/drive/items/' + itemId + '/content';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(sharepointUrl);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('HTTP Status: ' + res.getStatus());
            System.debug('HTTP Response: ' + res.getBody());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 204) {
                return sharepointUrl; // Return the URL for download
            } else if (res.getStatusCode() == 302) {
                return res.getHeader('Location'); // Return the redirect URL for download
            } else {
                throw new CalloutException('Error during callout: ' + res.getStatus() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred while getting download URL: ' + e.getMessage());
            throw new CalloutException('Error during callout: ' + e.getMessage());
        }
    }

    // Custom Exceptions
    public class AuthenticationException extends Exception {}
    public class CalloutException extends Exception {}
    public class SiteIdNotFoundException extends Exception {}
}