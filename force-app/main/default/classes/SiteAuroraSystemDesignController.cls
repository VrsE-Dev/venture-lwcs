public with sharing class SiteAuroraSystemDesignController {

    @AuraEnabled(Cacheable=true)
    public static List<Allowed_Array__c> getAllowedArrays(String siteId) {
        List<Allowed_Array__c> allowedArrays = new List<Allowed_Array__c>();
        
        for (Allowed_Array__c allowedArray: [SELECT Id, Site__c, Name, Number_of_Panels__c, TSRF__c FROM Allowed_Array__c WHERE Site__c = :siteId ORDER BY TSRF__c ASC]) {
            System.debug('Allowed array:');
            System.debug(allowedArray.Id);
            System.debug(allowedArray.Name);
            allowedArrays.add(allowedArray);
        }

        return allowedArrays;
    }
}