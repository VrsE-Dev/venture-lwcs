public with sharing class AuroraProjectSiteButtonController {
    @AuraEnabled
    public static string createAuroraProject(String site, String siteAccount){
        //System.debug('Site Id: ' + site.Id);
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        //String tenantId  = auroraSettings.Tenant_Id__c;
        String tenantId  = '3d26171f-d1f3-4a9e-af93-9040f89e8fd1';
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

        httpRequest.setBody(EncodingUtil.urlEncode(requestBody, 'UTF-8'));
        String strResponse = null;
        try {  
            Http http = new Http();   
            HttpResponse httpResponse = http.send(httpRequest);  
            if (httpResponse.getStatusCode() == 200) {  
                strResponse = httpResponse.getBody();  
                System.debug(strResponse);
                //site.Aurora_Project_Id__c = strResponse['project']['id'];
                //update site;
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

    @TestVisible 
    private static HttpRequest getAuroraEndpoint(String apiEndpoint, String httpMethod) {
        Aurora_Settings__c auroraSettings = Aurora_Settings__c.getInstance();
        String baseUrl   = auroraSettings.Base_URL__c;
        //String baseUrl   = 'https://api-sandbox.aurorasolar.com';
        String auroraKey = 'AuroraKey=' + auroraSettings.Aurora_Key__c;
        //String auroraKey = 'AuroraKey=3a35ce58-b703-4472-bbac-b5c5036edef2';
        String requestVerb = httpMethod;

        System.info(baseUrl);
        System.info(auroraKey);
        
        System.debug('unencoded time: ' + Datetime.now());
        String timestamp = 'Timestamp=' + EncodingUtil.urlEncode((Datetime.now() + ' UTC'), 'UTF-8').replaceAll('\\+', '%20');
        timestamp = timestamp.replaceAll('%3A', ':');
        
        System.debug('encoded time: ' + timestamp);
        System.debug(auroraSettings.Aurora_Key__c);
        
        String signature = 'Signature=' + calculateSignature(requestVerb, apiEndpoint, auroraKey, timestamp);
		
        String endpoint = baseUrl + apiEndpoint + '?' + auroraKey + '&' + timestamp + '&' + signature;

        System.info('endpoint: ' + endpoint);
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod(requestVerb);

        return httpRequest;
    }

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
}