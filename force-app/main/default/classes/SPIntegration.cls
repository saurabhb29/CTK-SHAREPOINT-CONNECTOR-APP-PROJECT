public class SPIntegration {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllFoldersAndFiles() {
        List<Map<String, Object>> itemsList = new List<Map<String, Object>>();

        String endpoint = 'callout:SharePoint_Named_Credentials/_api/web/lists/GetByTitle(\'Documents\')/items?$expand=Folder,File,Editor&$select=Title,FileLeafRef,Modified,Editor/Title,File/Length,Folder/ItemCount';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Response Status: ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Response Body Deserialized: ' + responseBody);
            List<Object> items = (List<Object>) responseBody.get('value');

            for (Object item : items) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                System.debug('Item: ' + itemMap);
                Map<String, Object> itemDetails = new Map<String, Object>();

                String title = (String) itemMap.get('Title');
                String itemName = (String) itemMap.get('FileLeafRef');
                String modified = (String) itemMap.get('Modified');
                Map<String, Object> editor = (Map<String, Object>) itemMap.get('Editor');
                String modifiedBy = editor != null ? (String) editor.get('Title') : 'Unknown';

                itemDetails.put('title', title);
                itemDetails.put('itemName', itemName);
                itemDetails.put('modified', modified);
                itemDetails.put('modifiedBy', modifiedBy);

                if (itemMap.containsKey('Folder')) {
                    Map<String, Object> folder = (Map<String, Object>) itemMap.get('Folder');
                    Integer childCount = (folder != null && folder.get('ItemCount') != null) ? Integer.valueOf(folder.get('ItemCount').toString()) : 0;
                    itemDetails.put('type', 'Folder');
                    itemDetails.put('childCount', childCount);
                    itemDetails.put('Folder', folder);
                    System.debug('Folder Details: ' + folder);
                } else if (itemMap.containsKey('File')) {
                    Map<String, Object> file = (Map<String, Object>) itemMap.get('File');
                    Integer fileSize = (file != null && file.get('Length') != null) ? Integer.valueOf(file.get('Length').toString()) : 0;
                    itemDetails.put('type', 'File');
                    itemDetails.put('fileSize', fileSize);
                    itemDetails.put('File', file);
                    System.debug('File Details: ' + file);
                }

                itemsList.add(itemDetails);
                System.debug('Item Details Added: ' + itemDetails);
            }
        } else {
            throw new AuraHandledException('Error from SharePoint: ' + res.getStatusCode() + ' ' + res.getBody());
        }

        System.debug('Final Items List: ' + itemsList);
        return itemsList;
    }
}