public class Testing100 {
    private static final String NAMED_CREDENTIAL = 'MyNamedCred';
    private static final String ENCRYPTION_KEY = '12345678901234567890123456789012'; // Replace with your actual 32-byte encryption key

    // Custom exception class
    public class AuthenticationException extends Exception {}

    // Method to save the encrypted access token into the custom object
    public static void saveAccessToken(String token) {
        try {
            // Encrypt the token
            Blob key = Blob.valueOf(ENCRYPTION_KEY);
            Blob data = Blob.valueOf(token);
            Blob encryptedData = Crypto.encryptWithManagedIV('AES256', key, data);
            String encryptedToken = EncodingUtil.base64Encode(encryptedData);

            // Delete existing token records before saving a new one
            List<AccessToken__c> oldTokenRecords = [SELECT Id FROM AccessToken__c];
            delete oldTokenRecords;

            // Save the new token record asynchronously
            saveAccessTokenAsync(encryptedToken);
        } catch (Exception e) {
            System.debug('Exception while saving access token: ' + e.getMessage());
            // Handle exception as needed
        }
    }

    // Asynchronous method to insert token record
    @future
    public static void saveAccessTokenAsync(String encryptedToken) {
        AccessToken__c tokenRecord = new AccessToken__c();
        tokenRecord.Token__c = encryptedToken;
        insert tokenRecord;
    }

    // Method to get the saved access token from the custom object
    public static String getSavedAccessToken() {
        try {
            List<AccessToken__c> tokenRecords = [SELECT Token__c FROM AccessToken__c ORDER BY CreatedDate DESC LIMIT 1];
            if (!tokenRecords.isEmpty()) {
                String encryptedToken = tokenRecords[0].Token__c;
                // Decrypt the token
                Blob key = Blob.valueOf(ENCRYPTION_KEY);
                Blob encryptedData = EncodingUtil.base64Decode(encryptedToken);
                Blob decryptedData = Crypto.decryptWithManagedIV('AES256', key, encryptedData);
                String token = decryptedData.toString();
                return token;
            }
        } catch (Exception e) {
            System.debug('Exception while getting saved access token: ' + e.getMessage());
            // Handle exception as needed
        }
        return null;
    }

    // Method to get a new access token and save it
    @AuraEnabled(cacheable=true)
    public static String getAccessToken() {
        try {
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

            if (res.getStatusCode() == 200 || res.getStatusCode() == 202) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String token = (String) responseMap.get('access_token');
                // Save the token asynchronously
                saveAccessToken(token);
                return token;
            } else {
                throw new AuthenticationException('Error authenticating to SharePoint: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception while getting access token: ' + e.getMessage());
            throw new AuthenticationException('Error authenticating to SharePoint: ' + e.getMessage());
        }
    }

    // Method to get a folder using a token
    @AuraEnabled(cacheable=true)
    public static String getFolder() {
        try {
            String token = getSavedAccessToken();
            if (token == null) {
                token = getAccessToken();
            }
            return getFolderWithToken(token);
        } catch (Exception e) {
            System.debug('Exception while getting folder: ' + e.getMessage());
            return 'An error occurred while retrieving the folder content.';
        }
    }

    // Method to get a folder using a specific token
    @AuraEnabled(cacheable=true)
    public static String getFolderWithToken(String token) {
        try {
            // Make sure token is retrieved and saved before making the callout
            if (token == null) {
                token = getAccessToken();
            }

            // Construct HTTP request
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://graph.microsoft.com/v1.0/sites/cynoteck.sharepoint.com,c9dee470-0a13-4670-882b-9764b2ea99aa,34774c41-d9c0-4be1-9dd6-6b24a35c22c5/drive/root/children';
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Accept', 'application/json');

            // Perform the HTTP callout
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle HTTP response
            if (res.getStatusCode() == 200 || res.getStatusCode() == 202) {
                // Handle successful response
                String responseBody = res.getBody();
                System.debug('Folder retrieved: ' + responseBody);
                return responseBody;
            } else {
                // Handle error response
                return httpErrorResponse(res);
            }
        } catch (Exception e) {
            System.debug('Exception while getting folder with token: ' + e.getMessage());
            return 'An error occurred while retrieving the folder content.';
        }
    }

    // Method to handle error response
    public static String httpErrorResponse(HttpResponse res) {
        Integer statusCode = res.getStatusCode();
        String responseBody = res.getBody();

        System.debug('Error status code: ' + statusCode);
        System.debug('Error response body: ' + responseBody);

        if (statusCode == 401) {
            // Handle authentication error
            System.debug('Authentication error. Regenerating token...');
            String token = getAccessToken();
            if (token != null) {
                // Retry folder retrieval with new token
                return getFolderWithToken(token);
            } else {
                System.debug('Failed to regenerate token.');
                return 'Authentication error. Please try again.';
            }
        } else {
            // Handle other errors
            return 'Error retrieving folder content: ' + responseBody;
        }
    }

    // Add a method to retrieve SharePoint folder based on configuration
    @AuraEnabled(cacheable=true)
    public static String getFolderConfig(String configType) {
        try {
            // Example logic to determine SharePoint folder based on configType
            String folderId = '';
            if (configType.equals('global')) {
                folderId = 'globalFolderId'; // Replace with your global folder ID logic
            } else if (configType.equals('recordType')) {
                folderId = getFolderIdByRecordType(); // Implement method to fetch folder based on record type
            }

            // Call method to get folder using folderId
            return getFolderWithId(folderId);
        } catch (Exception e) {
            System.debug('Exception while getting folder: ' + e.getMessage());
            return 'An error occurred while retrieving the folder content.';
        }
    }

    // Method to get a folder using a specific ID
    @AuraEnabled(cacheable=true)
    public static String getFolderWithId(String folderId) {
        try {
            // Construct HTTP request using folderId
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://graph.microsoft.com/v1.0/sites/cynoteck.sharepoint.com/' + folderId + '/drive/root/children';
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + getSavedAccessToken());
            req.setHeader('Accept', 'application/json');

            // Perform the HTTP callout
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Handle HTTP response
            if (res.getStatusCode() == 200 || res.getStatusCode() == 202) {
                // Handle successful response
                String responseBody = res.getBody();
                System.debug('Folder retrieved: ' + responseBody);
                return responseBody;
            } else {
                // Handle error response
                return httpErrorResponse(res);
            }
        } catch (Exception e) {
            System.debug('Exception while getting folder with ID: ' + e.getMessage());
            return 'An error occurred while retrieving the folder content.';
        }
    }

    // Example method to fetch folder ID based on record type (replace with actual logic)
    private static String getFolderIdByRecordType() {
        // Implement your logic to fetch folder ID based on record type
        // This is just a placeholder
        return 'recordTypeFolderId';
    }
}
