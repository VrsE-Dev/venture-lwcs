public with sharing class OpportunitySalesReportingController {
    @AuraEnabled
    public static List<Event> getAppointments(String opportunityId) {
        List<Event> appointments = new List<Event>();

        for (Event appointment: [SELECT Id, WhatId, StartDateTime, Appointment_Status__c, Notes__c, Subject FROM Event WHERE WhatId = :opportunityId ORDER BY StartDateTime DESC]) {
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
        return getMappedPicklistValues(objFieldDescribe);
    }

    @AuraEnabled
    public static Map<String, String> getQuoteRoofAgePicklistValues(){
        Schema.DescribeFieldResult objFieldDescribe = Quote.Roof_age__c.getDescribe();
        return getMappedPicklistValues(objFieldDescribe);
    }

    @AuraEnabled
    public static Map<String, String> getQuoteShingleLayersPicklistValues(){
        Schema.DescribeFieldResult objFieldDescribe = Quote.Layers_of_shingles__c.getDescribe();
        return getMappedPicklistValues(objFieldDescribe);
    }

    @AuraEnabled
    public static Map<String, String> getQuoteFinanceTypePicklistValues(){
        Schema.DescribeFieldResult objFieldDescribe = Quote.Accepted_Finance_Type__c.getDescribe();
        return getMappedPicklistValues(objFieldDescribe);
    }

    @AuraEnabled
    public static void reportSale(String opportunityId, String quoteId, String appointmentId, Map<String, Object> appointmentUpdates, Map<String, Object> quoteUpdates){
       try {
           updateAppointment(appointmentId, appointmentUpdates);
           updateQuote(quoteId, quoteUpdates);
           updateOpportunity(opportunityId);
       } catch (DmlException e) {
            System.debug('Error updating');
            System.debug(e);

            throw e;
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

                throw e;
            }
        }
    }

    @TestVisible
    private static void updateQuote(String quoteId, Map<String, Object> updates){
        updates.put('Status', 'Accepted');

        String soqlString = generateSoqlStringForUpdate('Quote', 'Id', quoteId, updates);

        System.debug('update quote soqlString:');
        System.debug(soqlString);

        Quote[] existingQuotes = Database.query(soqlString);
        Quote quote;

        if (existingQuotes.size() > 0) {
            quote = new Quote();

            for (String key: updates.keySet()) {
                System.debug(key);
                System.debug(updates.get(key));
                quote.put(key, updates.get(key));
            }
            quote.put('Id', existingQuotes[0].Id);

            System.debug(quote);

            try {
                update quote;
            } catch (DmlException e) {
                System.debug('Error updating quote');
                System.debug(e);

                throw e;
            }
        }
    }

    @TestVisible
    private static void updateOpportunity(String opportunityId){
        Map<String, Object> opportunityUpdates = new Map<String, Object>();
        opportunityUpdates.put('StageName', 'Site Assessment');
        opportunityUpdates.put('Opportunity_Disposition__c', 'Closed Won Pending');
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

                throw e;
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

    @TestVisible
    private static Map<String, String> getMappedPicklistValues(Schema.DescribeFieldResult objFieldDescribe) {
        List<Schema.PicklistEntry> lstPicklistValues = objFieldDescribe.getPickListValues();
        Map <String, String> mappedPicklistValues = new Map<String, String>();

        for (Schema.PicklistEntry objPicklist : lstPicklistValues) {
            System.debug('Value = ' +objPicklist.getValue() +' , Label = ' +objPicklist.getLabel());
            mappedPicklistValues.put(objPicklist.getValue(), objPicklist.getLabel());
        }

        return mappedPicklistValues;
    }
}