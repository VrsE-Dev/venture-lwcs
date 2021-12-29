public with sharing class AuroraProjectSiteButtonController {
    @AuraEnabled
    public static Object createAuroraProject(String siteId, String accountId){
        //System.debug('Site Id: ' + site.Id);
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        //String tenantId  = auroraSettings.Tenant_Id__c;
        String tenantId  = '3d26171f-d1f3-4a9e-af93-9040f89e8fd1';
        
        Account account = getAccountFields(accountId);
        String userName = getContactName(accountId);
        String fullAddress = getFullAddress(account.BillingAddress);

        String name = '';
        if (fullAddress != '') {
            name = fullAddress;
        } else {
            name = userName + ' Project';
        }

        String requestBody = '{'+
            '"name": "' + name + '",' +
            '"customer_first_name": "' + userName + '",' +
            '"customer_last_name": "' + userName + '",' +
            '"address":"' + fullAddress + '",' +
            '"project_type": "residential",' +
            '"external_provider_id": "8e68fcd1-af22-4c67-b286-c59f9101d239",' + 
            '"owner_id": "8e68fcd1-af22-4c67-b286-c59f9101d239"' +
        '}';

        System.debug('requestBody:');
        System.debug(requestBody);

        HttpRequest httpRequest = getAuroraEndpointPost('tenants/' + tenantId + '/projects', requestBody, 'project'); 
        //System.debug(httpRequest);

        String strResponse = null;
        try {  
            Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            System.debug(httpResponse);
            if (httpResponse.getStatusCode() == 200) {  
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());
                System.debug(response);

                Site__c site = getSiteFields(siteId);
                Map<String, Object> project = (Map<String, Object>)response.get('project');
                site.Aurora_Project_Id__c = (String)project.get('id');

                System.debug('site.Aurora_Project_Id__c:');
                System.debug(site.Aurora_Project_Id__c);
                update site;

                return response;  
            } 
            else {  
                throw new CalloutException(httpResponse.getBody());  
            }
        }
        catch(Exception ex) {  
            throw ex;  
        } 

        // return strResponse;
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

    @AuraEnabled
    public static Aurora_Settings__c getAuroraSettings(){
        try {
            Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();

            return auroraSettings;
        } catch (Exception e) {
            throw new AuraHandledException('Could not find Aurora Settings');
        }
    }

    @TestVisible 
    private static string getFullAddress(System.Address address){
        String fullAddress = '';
        if (address.getStreet() != null) {
            fullAddress += address.getStreet();
        }

        if (address.getCity() != null) {
            fullAddress += ', ' + address.getCity();
        }

        if (address.getState() != null) {
            fullAddress += ', ' + address.getState();
        }

        if (address.getPostalCode() != null) {
            fullAddress += ', ' + address.getPostalCode();
        }

        return fullAddress;
    }

    @TestVisible 
    private static HttpRequest getAuroraEndpointPost(String apiEndpoint, String requestBody, String bodyKey) {
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        
        String baseUrl   = auroraSettings.Base_URL__c + '/v2/';
        String auroraKey = auroraSettings.Aurora_Secret_New__c;
        String requestVerb = 'POST';

        System.debug('Authorization:');
        System.debug(auroraKey);
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(baseUrl + apiEndpoint);
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Authorization', auroraKey);
        httpRequest.setMethod(requestVerb);
        httpRequest.setBody(requestBody);

        return httpRequest;
    }
}