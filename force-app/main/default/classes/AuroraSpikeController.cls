public with sharing class AuroraSpikeController {
    @AuraEnabled
    public static PV_Modules__c getPVModule(String auroraPanelName){
        try {
            PV_Modules__c pvModule = new PV_Modules__c();
    
            pvModule = [
                SELECT
                    Id,
                    Aurora_Panel_Name__c
                FROM 
                    PV_Modules__c
                WHERE
                    Aurora_Panel_Name__c = :auroraPanelName
                LIMIT
                    1
            ].get(0);
    
            return pvModule;
        } catch (Exception e) {
            throw new AuraHandledException('Couldnt find PV Module to map to Aurora Module');
        }
    }

    @AuraEnabled
    public static String upsertPVSystem(String quoteId, Map<String, Object> changes){
        String soqlString = generateSoqlStringForUpdate('PV_System__c', 'Quote__r.Id', quoteId, changes);
 
        System.debug('upsertPVSystem soqlString:');
        System.debug(soqlString);
        PV_System__c[] existingPvSystemArr = Database.query(soqlString);
        PV_System__c pvSystem;

        System.debug(existingPvSystemArr);

        if(existingPvSystemArr.size() > 0) {
            System.debug('existingPvSystem');
            pvSystem = new PV_System__c();

            for (String key: changes.keySet()) {
                System.debug(key);
                System.debug(changes.get(key));
                if(key != 'Account__c') {
                    pvSystem.put(key, changes.get(key));
                }
            }
            pvSystem.put('Id', existingPvSystemArr[0].Id);
            System.debug(pvSystem);
 
            try {
                update pvSystem;
            } catch(DmlException e) {
                System.debug('error updating pv system');
                System.debug(e);
            }

            // delete arrays associated to pv system
            List<PV_Array__c> pvArrays = new List<PV_Array__c>();
        
            pvArrays = [
                SELECT
                    Id,
                    PV_System__r.Id
                FROM
                    PV_Array__c
                WHERE
                    PV_System__r.Id = :pvSystem.Id
            ];

            try {
                delete pvArrays;
                return pvSystem.Id;
            } catch(DmlException e) {
                System.debug('error deleting associated pv arrays');
                System.debug(e);
                throw e;
            }

        } else {
            System.debug('notExistingPvSystem');
            pvSystem = (PV_System__c)populateObjectForUpdate(new PV_System__c(), changes);

            try {
                insert pvSystem;
                return pvSystem.Id;
            } catch(DmlException e) {
                System.debug('error inserting new pv system');
                System.debug(e);
                throw e;
            }
        }
    }


    @AuraEnabled(Cacheable=true)
    public static Account getAccountFields(String accountId){
        try {
            Account account = new Account();
    
            account = [
                SELECT
                    Id,
                    Site,
                    BillingAddress,
                    OwnerId
                FROM 
                    Account 
                WHERE
                    Id = :accountId
            ];

            return account;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting account');
        }
    }

    @AuraEnabled(Cacheable=true)
    public static Site__c getSiteFields(String siteId){
        try {
            Site__c site = new Site__c();
    
            site = [
                SELECT
                    Id,
                    Account__c,
                    Aurora_Project_Id__c
                FROM 
                    Site__c
                WHERE
                    Id = :siteId
                LIMIT
                    1
            ].get(0);
    
            return site;
        } catch(Exception e) {
            throw new AuraHandledException('Couldnt find Site associated with Account Id: ' + siteId);
        }
    }

    @AuraEnabled(Cacheable=true)
    public static string getProjectDesigns(String projectId){
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String tenantId = auroraSettings.Tenant_Id__c;
        // String tenantId  = '3d26171f-d1f3-4a9e-af93-9040f89e8fd1';
        HttpRequest httpRequest = getAuroraEndpoint('/v2/tenants/' + tenantId + '/projects/' + projectId + '/designs', 'GET'); 

        String strResponse = null;
        try {  
          Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            if (httpResponse.getStatusCode() == 200 ) {  
                strResponse = httpResponse.getBody();  
                System.debug(strResponse);
            } 
            else {  
                throw new CalloutException(httpResponse.getBody());  
            } 
        } 
        catch(Exception ex) {  
            throw ex;  
        } 

        if(!String.isBlank(strResponse)) {
            return strResponse;
        } else{
            return null;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static string getContactName(string accountId){
        try{
            Contact user = new Contact();

            user = [
                SELECT
                    id, 
                    Full_Name__c,
                    AccountId
                FROM 
                    Contact
                WHERE
                    AccountId = :accountId
                LIMIT 1
            ].get(0);
            return user.Full_Name__c;
        }
        catch(Exception e) {
            throw new AuraHandledException('Couldnt find Contact associated with AccountId: ' + accountId);
        }
    }

    @AuraEnabled(Cacheable=true)
    public static string createAuroraProject(String site, String siteAccount){
        //System.debug('Site Id: ' + site.Id);
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String tenantId  = auroraSettings.Tenant_Id__c;
        // String tenantId  = '3d26171f-d1f3-4a9e-af93-9040f89e8fd1';
        HttpRequest httpRequest = getAuroraEndpoint('/v2/tenants/' + tenantId + '/projects/', 'POST'); 

        Account account = getAccountFields(siteAccount);
        String userName = getContactName(siteAccount);

        String requestBody = '"project":{'+
            '"name":"' + account.BillingAddress + ',' +
            '"customer_first_name":"' + userName + ',' +
            '"customer_last_name":"' + userName + ',' +
            '"customer_address":' + account.BillingAddress + ',' +
            '"project_type":"residential",' +
            '"external_provider_id:' + account.OwnerId + '}';
            //'"Customer_First_Name:' + site.Account__c.FirstContact + ',' +

        httpRequest.setBody(requestBody);
        String strResponse = null;
        try {  
         	Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            if (httpResponse.getStatusCode() == 200) {  
                strResponse = httpResponse.getBody();  
                System.debug(strResponse);
                //site.Aurora_Project_Id__c = strResponse['project']['id'];
                update site;
            } 
            else {  
                throw new CalloutException(httpResponse.getBody());  
            }
        }
        catch(Exception ex) {  
            throw ex;  
        } 

        return strResponse;
        
    }

    @AuraEnabled(Cacheable=true)
    public static string getDesignSummary(String designId){
        System.debug('Design Id: ' + designId);
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String tenantId  = auroraSettings.Tenant_Id__c;
        // String tenantId  = '3d26171f-d1f3-4a9e-af93-9040f89e8fd1';
        HttpRequest httpRequest = getAuroraEndpoint('/v2/tenants/' + tenantId + '/designs/' + designId + '/summary', 'GET'); 

        String strResponse = null;
        try {  
         	Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            if (httpResponse.getStatusCode() == 200 ) {  
                strResponse = httpResponse.getBody();  
                System.debug(strResponse);
            } 
            else {  
                throw new CalloutException(httpResponse.getBody());  
            } 
        
        } 
        catch(Exception ex) {  
            throw ex;  
        } 
        
        if(!String.isBlank(strResponse)) {
            return strResponse;
        } else{
            return null;
        }
    }
    
    @TestVisible 
    private static HttpRequest getAuroraEndpoint(String apiEndpoint, String httpMethod) {
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String baseUrl   = auroraSettings.Base_URL__c;
        // String baseUrl   = 'https://api-sandbox.aurorasolar.com';
        String auroraKey = 'AuroraKey=' + auroraSettings.Aurora_Key__c;
        // String auroraKey = 'AuroraKey=3a35ce58-b703-4472-bbac-b5c5036edef2';
        String requestVerb = httpMethod;
        
        System.debug('unencoded time: ' + Datetime.now());
        String timestamp = 'Timestamp=' + EncodingUtil.urlEncode((Datetime.now() + ' UTC'), 'UTF-8').replaceAll('\\+', '%20');
        timestamp = timestamp.replaceAll('%3A', ':');
        
        System.debug('encoded time: ' + timestamp);
        
        String signature = 'Signature=' + calculateSignature(requestVerb, apiEndpoint, auroraKey, timestamp);
		
        String endpoint = baseUrl + apiEndpoint + '?' + auroraKey + '&' + timestamp + '&' + signature;

        System.debug('endpoint: ' + endpoint);
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod(requestVerb);

        return httpRequest;
    }
    
    @TestVisible 
    private static HttpRequest getAuroraEndpoint(String apiEndpoint, String httpMethod, List<String> stringQueries) {
        String baseUrl   = 'https://api-sandbox.aurorasolar.com';
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String auroraKey = 'AuroraKey=' + auroraSettings.Aurora_Key__c;
        String requestVerb = httpMethod;
        
        System.debug('unencoded time: ' + Datetime.now());
        String timestamp = 'Timestamp=' + EncodingUtil.urlEncode((Datetime.now() + ' UTC'), 'UTF-8').replaceAll('\\+', '%20');
        timestamp = timestamp.replaceAll('%3A', ':');
        
        System.debug('encoded time: ' + timestamp);
        
        String signature = 'Signature=' + calculateSignature(requestVerb, apiEndpoint, auroraKey, timestamp, stringQueries);
		
        String queryString = '';
        for (Integer i = 0; i < stringQueries.size(); i++) {
            queryString = queryString + stringQueries[i];
        }
        
        String endpoint = baseUrl + apiEndpoint + '?' + auroraKey + '&' + timestamp + '&' + queryString + '&' + signature;

        System.debug('endpoint: ' + endpoint);
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod(requestVerb);

        return httpRequest;
    }

    @TestVisible 
    private static String calculateSignature(String requestVerb, String apiEndpoint, String auroraKey, String timestamp) { 
        String[] parameters = new List<String>();
        parameters.add(requestVerb + '\n');
        parameters.add(apiEndpoint + '\n');
        parameters.add(auroraKey + '\n');
        parameters.add(timestamp + '\n');      
        
        String canonicalSignature = '';
        for (Integer i = 0; i < parameters.size(); i++) {
            canonicalSignature = canonicalSignature + parameters[i];
        }
        System.debug('canonical signature:');
		System.debug(canonicalSignature);
        
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String auroraSecret = auroraSettings.Aurora_Secret__c;
        
        Blob hmac = crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalSignature), Blob.valueOf(auroraSecret));
        //System.debug('signature bytes:');
        //System.debug(hmac.toString());
        
        String signature64 = EncodingUtil.base64Encode(hmac);
        System.debug('signature 64:');
        System.debug(signature64);
      
        String signature = EncodingUtil.urlEncode(signature64, 'UTF-8');
        return signature;
    }
    
    @TestVisible 
    private static String calculateSignature(String requestVerb, String apiEndpoint, String auroraKey, String timestamp, List<String> stringQueries) { 
        AuroraParam[] queries = new List<AuroraParam>();
        for (Integer i = 0; i < stringQueries.size(); i++) {
            queries.add(new AuroraParam(stringQueries[i]));
        }
        queries.sort();
        
        String queryString = '';
        for (Integer i = 0; i < queries.size(); i++) {
            queryString = queryString + queries[i].param;
        }
        
        String[] parameters = new List<String>();
        parameters.add(requestVerb + '\n');
        parameters.add(apiEndpoint + '\n');
        parameters.add(auroraKey + '\n');
        parameters.add(timestamp + '\n');
        parameters.add(queryString + '\n');
        
        String canonicalSignature = '';
        for (Integer i = 0; i < parameters.size(); i++) {
            canonicalSignature = canonicalSignature + parameters[i];
        }
        System.debug('canonical signature:');
		System.debug(canonicalSignature);
        
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String auroraSecret = auroraSettings.Aurora_Secret__c;
        
        Blob hmac = crypto.generateMac('HmacSHA256', Blob.valueOf(canonicalSignature), Blob.valueOf(auroraSecret));
        //System.debug('signature bytes:');
        //System.debug(hmac.toString());
        
        String signature64 = EncodingUtil.base64Encode(hmac);
        System.debug('signature 64:');
        System.debug(signature64);
      
        String signature = EncodingUtil.urlEncode(signature64, 'UTF-8');
        return signature;
    }

    @TestVisible 
    private static String generateSoqlStringForUpdate(String objectForUpdate, String matchField, String id, Map<String, Object> changes) {
        Integer keyCounter = 0;
        String soqlString = 'SELECT Id, ';
        for (String key : changes.keySet()) {
            keyCounter++;

            if(key != '')
            soqlString += key;

            if(keyCounter < changes.size()) {
                soqlString += ', ';
            } else {
                soqlString += ' ';
            }
        }
        soqlString += 'FROM ' + objectForUpdate + ' WHERE ' + matchField + ' = \'' + id + '\' FOR UPDATE';

        return soqlString;
    }

    @TestVisible 
    private static SObject populateObjectForUpdate(SObject objectForUpdate, Map<String, Object> changes) {
        System.debug(objectForUpdate);
        for (String key: changes.keySet()) {
            System.debug(key);
            System.debug(changes.get(key));
            objectForUpdate.put(key, changes.get(key));
        }

        return objectForUpdate;
    }
}