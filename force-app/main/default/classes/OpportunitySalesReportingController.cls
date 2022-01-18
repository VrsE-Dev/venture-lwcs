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

        System.debug('OpportunityId:');
        System.debug(opportunityId);
        System.debug('Getting quotes related to opportunity');
        for (Quote quote: [SELECT Id, OpportunityId, Name, Status, Number_of_Panels__c, System_Size__c FROM Quote WHERE OpportunityId = :opportunityId]) {
            quotes.add(quote);
        }

        System.debug('Quotes related to opportunity:');
        System.debug(quotes);

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

    @AuraEnabled
    public static void reportSale(String opportunityId, String quoteId, String appointmentId, Map<String, Object> appointmentUpdates){
       try {
           updateAppointment(appointmentId, appointmentUpdates);
           updateQuote(quoteId);
           updateOpportunity(opportunityId);
       } catch (DmlException e) {
            System.debug('Error updating');
            System.debug(e);
       }
    }
    
    @TestVisible
    private static void updateAppointment(String appointmentId, Map<String, Object> changes){
        String soqlString = generateSoqlStringForUpdate('Event', 'Id', appointmentId, changes);

        System.debug('update appointment soqlString:');
        System.debug(soqlString);

        Event[] existingAppointments = Database.query(soqlString);
        Event appointment;

        if (existingAppointments.size() > 0) {
            appointment = new Event();

            for (String key: changes.keySet()) {
                System.debug(key);
                System.debug(changes.get(key));
                appointment.put(key, changes.get(key));
            }
            appointment.put('Id', existingAppointments[0].Id);

            System.debug(appointment);

            try {
                update appointment;
            } catch (DmlException e) {
                System.debug('Error updating event');
                System.debug(e);
            }
        }
    }

    @TestVisible
    private static void updateQuote(String quoteId){
        Map<String, Object> quoteUpdates = new Map<String, Object>();
        quoteUpdates.put('Status', 'Accepted');

        String soqlString = generateSoqlStringForUpdate('Quote', 'Id', quoteId, quoteUpdates);

        System.debug('update quote soqlString:');
        System.debug(soqlString);

        Quote[] existingQuotes = Database.query(soqlString);
        Quote quote;

        if (existingQuotes.size() > 0) {
            quote = new Quote();

            for (String key: quoteUpdates.keySet()) {
                System.debug(key);
                System.debug(quoteUpdates.get(key));
                quote.put(key, quoteUpdates.get(key));
            }
            quote.put('Id', existingQuotes[0].Id);

            System.debug(quote);

            try {
                update quote;
            } catch (DmlException e) {
                System.debug('Error updating quote');
                System.debug(e);
            }
        }
    }

    @TestVisible
    private static void updateOpportunity(String opportunityId){
        Map<String, Object> opportunityUpdates = new Map<String, Object>();
        opportunityUpdates.put('Stage', 'Site Assessment');

        String soqlString = generateSoqlStringForUpdate('Opportunity', 'Id', opportunityId, opportunityUpdates);

        System.debug('update opportunity soqlString:');
        System.debug(soqlString);

        Opportunity[] existingOpportunities = Database.query(soqlString);
        Opportunity opportunity;

        if (existingOpportunities.size() > 0) {
            opportunity = new Opportunity();

            for (String key: opportunityUpdates.keySet()) {
                System.debug(key);
                System.debug(opportunityUpdates.get(key));
                opportunity.put(key, opportunityUpdates.get(key));
            }
            opportunity.put('Id', existingOpportunities[0].Id);

            System.debug(opportunity);

            try {
                update opportunity;
            } catch (DmlException e) {
                System.debug('Error updating opportunity');
                System.debug(e);
            }
        }
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
}