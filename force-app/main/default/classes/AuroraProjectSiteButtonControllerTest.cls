@isTest
public class AuroraProjectSiteButtonControllerTest {
    static Account configureAccount() {
        String userId = UserInfo.getUserId();
    
        Production_Region__c productionRegion = new Production_Region__c(
            Name = 'Test Production Region',
            Production_Factor__c = .85,
            Production_Factor_Regional_Adjustment__c = .05
        );
        insert productionRegion;
        
        Zip_Code__c zipCode = new Zip_Code__c(
            NYC_Borough__c = 'Brooklyn',
            State__c = 'NY',
            Production_Region__c = productionRegion.Id
        );
        insert zipCode;
        
        Account acct = new Account(
            Zip_Code__c = zipCode.Id,
            Name = 'Test Acct',
            RecordTypeId = '01261000000REeEAAW'
        );
        
        acct.BillingStreet = 'Washington St';
        acct.BillingCity = 'Newton';
        acct.BillingState = 'Massachusetts';
        acct.BillingCountry = 'United States';
        acct.BillingPostalCode = '02465';
    
        insert acct;
        
        acct = [Select BillingAddress, Zip_Code__c, Name from Account where Id = :acct.Id];
        
        return acct;
    }
    
    static Contact configureContact(String accountId) {
        String userId = UserInfo.getUserId();
    
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = accountId
        );
    
        insert contact;
    
        return contact;
    }
    
    static Site__c configureSite(String accountId) {
    	Site__c site = new Site__c(
            Account__c = accountId
        );
        
        insert site;    
        
        return site;
    }
    
    static Aurora_Settings__c configureCustomSettings() {
        Aurora_Settings__c settings = new Aurora_Settings__c();
        
        settings = new Aurora_Settings__c();
        settings.Aurora_Key__c = 'auroraKey';
        settings.Aurora_Secret__c = 'auroraSecret';
        settings.Aurora_Secret_New__c = 'auroraSecretNew';
        settings.Base_URL__c = 'v2/tenants';
        settings.Tenant_Id__c = 'tenantId';
        insert settings;  
        
        System.debug('Aurora_Settings');
        System.debug(settings.Aurora_Key__c);
        System.debug(settings.Aurora_Secret__c);
        System.debug(settings.Base_URL__c);
        System.debug(settings.Tenant_Id__c);
        
        return settings;
    }
    
    @isTest static void getContactName() {
    	Account acct = configureAccount();
        Contact contact = configureContact(acct.Id);
        
        Test.startTest();
        String testContactName = AuroraProjectSiteButtonController.getContactName(acct.Id);
        Test.stopTest();
        System.assertEquals(testContactName, 'Test Contact');
    }
    
    @isTest static void getAccountFields() {
        Account acct = configureAccount();
        
        Test.startTest();
        Account testAccount = AuroraProjectSiteButtonController.getAccountFields(acct.Id);
        Test.stopTest();
        
        System.assertEquals(testAccount.Id, acct.Id);
    }
    
    @isTest static void getSiteFields() {
        Account acct = configureAccount();
        Site__c site = configureSite(acct.Id);
        
        Test.startTest();
        Site__c testSite = AuroraProjectSiteButtonController.getSiteFields(site.Id);
        Test.stopTest();
        
        System.assertEquals(site.Id, testSite.Id);
    }
    
    @isTest static void getAuroraSettings() {
        Aurora_Settings__c auroraSettings = configureCustomSettings();
        
        Test.startTest();
        Aurora_Settings__c testAuroraSettings = AuroraProjectSiteButtonController.getAuroraSettings();
        Test.stopTest();
        
        System.assertEquals(testAuroraSettings.Base_URL__c, auroraSettings.Base_URL__c);
    }
    
    @isTest static void getFullAddress() {
        Account acct = configureAccount();
        
        System.debug(acct);
        System.debug(acct.BillingAddress);
        Test.startTest();
        String fullAddress = AuroraProjectSiteButtonController.getFullAddress(acct.BillingAddress);
        Test.stopTest();
        
        System.assertEquals(fullAddress, 'Washington St, Newton, Massachusetts, 02465');
    }
    
    @isTest static void getAuroraEndpointPost() {
        Aurora_Settings__c auroraSettings = configureCustomSettings();
        Test.setMock(HttpCalloutMock.class, new AuroraSpikeHttpCalloutMock());
        
        Test.startTest();
        HttpRequest httpRequest = AuroraProjectSiteButtonController.getAuroraEndpointPost('tenants/testId/projects', '', 'project');
        Test.stopTest();
        
        System.assertEquals('POST', httpRequest.getMethod());        
    }    
    
    @isTest static void canCreateAuroraProject() {
    	Aurora_Settings__c settings = configureCustomSettings();
        Account acct = configureAccount();
        Site__c site = configureSite(acct.Id);
        Contact contact = configureContact(acct.Id);
		Test.setMock(HttpCalloutMock.class, new AuroraSpikeHttpCalloutMock());        
        
        Test.startTest();
        Map<String, Object> res = (Map<String, Object>)AuroraProjectSiteButtonController.createAuroraProject(site.Id, acct.Id);
        Test.stopTest();
        
        site = [Select Id, Aurora_Project_Id__c From Site__c where Id = :site.Id];
        Map<String, Object> project = (Map<String, Object>)res.get('project');
        System.assertEquals(site.Aurora_Project_Id__c, 'testId');
        System.assertEquals((String)project.get('id'), 'testId');
    }
}