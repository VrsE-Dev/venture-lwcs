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