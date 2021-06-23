@isTest
public class SiteAuroraSystemDesignControllerTest {
    static Account configureAccount() {
        String userId = UserInfo.getUserId();

        Zip_Code__c zipCode = new Zip_Code__c(
        	NYC_Borough__c = 'Brooklyn',
            State__c = 'NY'
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

   @isTest static void getAllowedArraysOrderedByTSRF() {
        Account acct = configureAccount();

        Site__c site = new Site__c(
            Account__c = acct.Id
        );
        insert site;
        
        Allowed_Array__c allowedArrayOne = new Allowed_Array__c(
            Site__c = site.Id,
            Number_of_Panels__c = 20,
            TSRF__c = 75
        );
        insert allowedArrayOne;

        Allowed_Array__c allowedArrayTwo = new Allowed_Array__c(
            Site__c = site.Id,
            Number_of_Panels__c = 15,
            TSRF__c = 65
        );
        insert allowedArrayTwo;

        Test.startTest();
        List<Allowed_Array__c> allowedArrays = SiteAuroraSystemDesignController.getAllowedArrays(site.Id);
        Test.stopTest();

        system.assertEquals(2, allowedArrays.size());
        system.assertEquals(allowedArrays.get(0).TSRF__c, 65);
    }
}