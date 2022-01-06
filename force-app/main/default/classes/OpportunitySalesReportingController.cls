public with sharing class OpportunitySalesReportingController {

    @AuraEnabled
    public static List<Event> getAppointments(String opportunityId) {
        List<Event> appointments = new List<Event>();

        for (Event appointment: [SELECT Id, WhatId, StartDateTime, Appointment_Status__c, Notes__c FROM Event WHERE WhatId = :opportunityId ORDER BY StartDateTime DESC]) {
            appointments.add(appointment);
        }

        return appointments;
    }

    @AuraEnabled
    public static List<Quote> getQuotes(String opportunityId) {
        List<Quote> quotes = new List<Quote>();

        for (Quote quote: [SELECT Id, OpportunityId, Name, Status, Number_of_Panels__c, System_Size__c FROM Quote WHERE OpportunityId = :opportunityId]) {
            quotes.add(quote);
        }

        return quotes;
    }

    @AuraEnabled
    public static Map<String, String> getAppointmentStatusPicklistValues(){
        Schema.DescribeFieldResult objFieldDescribe = Event.Appointment_Status__c.getDescribe();
        List<Schema.PicklistEntry> lstPicklistValues = objFieldDescribe.getPickListValues();
        Map <String, String> mappedPicklistValues = new Map<String, String>();

        for (Schema.PicklistEntry objPicklist : lstPicklistValues) {
            System.debug('Value = ' +objPicklist.getValue() +' , Label = ' +objPicklist.getLabel());
            mappedPicklistValues.put(objPicklist.getValue(), objPicklist.getLabel());
        }

        return mappedPicklistValues;
    }
}