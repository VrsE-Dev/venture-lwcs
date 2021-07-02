@isTest
public class AuroraSpikeControllerTest {
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
        insert acct;
        
        return acct;
    }

    static PV_System__c configurePVSystem() {
        Account acct = configureAccount();

        Site__c site = new Site__c(
            Account__c = acct.Id
        );
        insert site;
        System.debug('Site__c');
        System.debug(site);
        
        System.debug([SELECT Id, Opportunity__c, Account__r.Id FROM Site__c WHERE Account__r.Id = :acct.Id ORDER BY CreatedDate LIMIT 1]);
        
        PV_Modules__c pvModule = new PV_Modules__c(
            Active__c = True,
        	Manufacturer__c = 'LG Electronics',
            PTC_Rating__c = 328,
            Name = 'CCC',
            Wattage__c = 100 
        );
        insert pvModule;

        Id oRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Venture Commercial').getRecordTypeId();
        
        Opportunity testOpportunity = new Opportunity(
            Name='Test Opportunity', 
            StageName='Closed Won', 
            Approved__c = true, 
            CloseDate = System.Today(), 
            RecordTypeid = oRecordTypeId,
            AccountId = acct.Id
        );
        insert testOpportunity;
        
        System.debug('Opportunity');
		System.debug(testOpportunity);
        
       
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = testOpportunity.Id,
            Finance__c = False
        );
        insert quote;

        PV_System__c pvSystem = new PV_System__c(
            Account__c = acct.Id,
            Inverter__c = 'Enphase IQ7',
            PV_Modules__c = pvModule.Id,
            Quote__c = quote.Id,
            Racking__c = 'IronRidge',
            Status__c = 'Proposed'
        );

        insert pvSystem;

        return pvSystem;
    }

    static PV_Array__c configurePVArray(String pvSystemId) {
        PV_Array__c pvArray = new PV_Array__c(
            Number_of_Panels__c = 30,
            TSRF__c = 85,
            PV_System__c = pvSystemId
        );
        
        insert pvArray;
        
        return pvArray;
    }
    
    static void configureCustomSettings() {
        Aurora_Settings__c settings = new Aurora_Settings__c();
    	
        settings = new Aurora_Settings__c();
        settings.Aurora_Key__c = 'auroraKey';
        settings.Aurora_Secret__c = 'auroraSecret';
        settings.Base_URL__c = 'v2/tenants';
        settings.Tenant_Id__c = 'tenantId';
        insert settings;  
        
        System.debug('Aurora_Settings');
        System.debug(settings.Aurora_Key__c);
        System.debug(settings.Aurora_Secret__c);
        System.debug(settings.Base_URL__c);
        System.debug(settings.Tenant_Id__c);
    }
    
    @isTest static void getPVModule() {
        PV_Modules__c pvModule = new PV_Modules__c(
            Manufacturer__c = 'LG Electronics',
            Aurora_Panel_Name__c = 'Test Aurora Panel Name',
            PTC_Rating__c = 10,
            Name = 'Test PV Module Name',
            Wattage__c = 10,
            Active__c = True
        );

        insert pvModule;

        Test.startTest();
        PV_Modules__c pvModuleMapped = AuroraSpikeController.getPVModule('Test Aurora Panel Name');
        Test.stopTest();

        System.assertEquals(pvModuleMapped.Aurora_Panel_Name__c, 'Test Aurora Panel Name');
    }

    @isTest static void updatePVSystemIfExists() {
        PV_System__c pvSystem = configurePVSystem();

        System.assertEquals(pvSystem.Status__c, 'Proposed');
        
        Test.startTest();
        Map<String, Object> changes = new Map<String, Object>();
        changes.put('Status__c', 'Contracted');
         
        String id = AuroraSpikeController.upsertPVSystem(pvSystem.Quote__c, changes);
		PV_System__c updatedPVSystem = [SELECT Id, Status__c FROM PV_System__c WHERE Id = :pvSystem.Id ORDER BY CreatedDate LIMIT 1];        
        Test.stopTest();
        
        System.assertEquals(updatedPVSystem.Status__c, 'Contracted');
    }

    @isTest static void deletePVSystemPVArraysIfExists() {
        PV_System__c pvSystem = configurePVSystem();
		PV_Array__c pvArray = configurePVArray(pvSystem.Id);
        
        Test.startTest();
        Map<String, Object> changes = new Map<String, Object>();
        changes.put('Status__c', 'Contracted');
         
        String id = AuroraSpikeController.upsertPVSystem(pvSystem.Quote__c, changes);
        Test.stopTest();
        
        System.assertEquals([SELECT Id FROM PV_Array__c WHERE Id = :pvArray.Id LIMIT 1], new List<PV_Array__c>());
    }

    @isTest static void getAccountFields() {
        Account acct = configureAccount();

        Test.startTest();
        Account testAccount = AuroraSpikeController.getAccountFields(acct.Id);
        Test.stopTest();

        System.assertEquals(testAccount.Id, acct.Id);
    }

    @isTest static void getSiteFields() {
        Account acct = configureAccount();
        Site__c site = new Site__c(
            Account__c = acct.Id,
            Aurora_Project_Id__c = '1'
        );

        insert site;

        Test.startTest();
        Site__c testSite = AuroraSpikeController.getSiteFields(acct.Id);
        Test.stopTest();

        System.assertEquals(testSite.Account__c, acct.Id);
    }

    @isTest static void getProjectDesigns() {
        configureCustomSettings();
        Test.setMock(HttpCalloutMock.class, new AuroraSpikeHttpCalloutMock());

        Test.startTest();
        String resStr = AuroraSpikeController.getProjectDesigns('string');
        Test.stopTest();

        String expectedValue = '{"designs": [{"id": "204a9559-de84-4c75-a971-1f7b4abd991e","external_provider_id": null,"name": "Test Design","system_size": 65160.0,"system_size_stc": 65160.0,"system_size_ptc": 61105.6,"system_size_ac": 24000.0}]}';
        System.assertEquals(resStr, expectedValue);
    }

    @isTest static void getDesignSummary() {
        configureCustomSettings();
        Test.setMock(HttpCalloutMock.class, new AuroraSpikeHttpCalloutMock());

        Test.startTest();
        String resStr = AuroraSpikeController.getDesignSummary('string');
        Test.stopTest();

        String expectedValue = '{"design": {"design_id": "204a9559-de84-4c75-a971-1f7b4abd991e","project_id": "a4b2b36a-2edf-4d78-aadc-a57b4767aef2","arrays": [{    "module": {        "id": "7545b2cc-0585-40fb-8eaf-2d475fa19d8f",        "name": "LG360Q1C-A5",        "manufacturer": "LG Electronics Inc.",        "rating_stc": 360,        "orientation": "portrait",        "count": 22    },    "strings": {        "count": 1    },    "azimuth": 75.8,    "pitch": 1.33,    "configuration": "string inverter",    "string_inverter": {        "index": 1    },    "face": 1,    "size": 7920}]}}';
        System.assertEquals(resStr, expectedValue);
    }
    
    @isTest static void getAuroraEndpointNoQueries() {
        configureCustomSettings();

        Test.startTest();
        HttpRequest auroraEndpoint = AuroraSpikecontroller.getAuroraEndpoint('/apiEndpoint', 'GET');
        Test.stopTest();
        
        System.assertEquals('GET', auroraEndpoint.getMethod());
        System.assertEquals(true, auroraEndpoint.getEndpoint().contains('/apiEndpoint'));
    }
    
    @isTest static void getAuroraEndpointQueries() {
        configureCustomSettings();

        List<String> stringQueries = new List<String>();
        stringQueries.add('queryOne');
        stringQueries.add('queryTwo');
        
        Test.startTest();
        HttpRequest auroraEndpoint = AuroraSpikecontroller.getAuroraEndpoint('/apiEndpoint', 'GET', stringQueries);
        Test.stopTest();
        
        System.assertEquals('GET', auroraEndpoint.getMethod());
        System.assertEquals(true, auroraEndpoint.getEndpoint().contains('https://api-sandbox.aurorasolar.com/apiEndpoint'));
    	System.assertEquals(true, auroraEndpoint.getEndpoint().contains('queryOne'));
        System.assertEquals(true, auroraEndpoint.getEndpoint().contains('queryTwo'));
    }
}