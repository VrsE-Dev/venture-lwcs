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
        HttpRequest httpRequest = getAuroraEndpointGet('tenants/' + tenantId + '/projects/' + projectId + '/designs'); 

        String strResponse = null;
        try {  
          Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            if (httpResponse.getStatusCode() == 200 ) {  
                strResponse = httpResponse.getBody();  
                System.debug('strResponse:');
        		System.debug(strResponse);
                
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
    public static string getDesignSummary(String designId){
        System.debug('Design Id: ' + designId);
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String tenantId  = auroraSettings.Tenant_Id__c;
        HttpRequest httpRequest = getAuroraEndpointGet('tenants/' + tenantId + '/designs/' + designId + '/summary'); 

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
    private static HttpRequest getAuroraEndpointGet(String apiEndpoint) {
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        
        String baseUrl   = auroraSettings.Base_URL__c + '/v2/';
        String auroraKey = auroraSettings.Aurora_Secret_New__c;
        String requestVerb = 'GET';

        HttpRequest httpRequest = new HttpRequest();  
        System.debug(baseUrl + apiEndpoint);
        httpRequest.setEndpoint(baseUrl + apiEndpoint);
        httpRequest.setHeader('Authorization', auroraKey);
        httpRequest.setMethod(requestVerb);

        return httpRequest;
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