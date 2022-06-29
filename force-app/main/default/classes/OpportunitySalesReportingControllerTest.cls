@isTest
public class OpportunitySalesReportingControllerTest {
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

    static Opportunity configureOpportunity() {
        Account acct = configureAccount();

        Id oRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Venture Commercial').getRecordTypeId();
        
        Opportunity opportunity = new Opportunity(
            Name='Test Opportunity', 
            StageName='Closed Won', 
            Approved__c = true, 
            CloseDate = System.Today(), 
            RecordTypeid = oRecordTypeId,
            AccountId = acct.Id
        );
        insert opportunity;

        return opportunity;
    }
    
    @isTest static void getAppointments() {
        Opportunity opportunity = configureOpportunity();

        Event appointment = new Event(
            StartDateTime = System.Today(),
            Appointment_Status__c = 'Confirmed',
            Appointment_Notes__c = 'Test Notes',
            WhatId = opportunity.Id,
            DurationInMinutes = 60,
            Type = 'Meeting',
            Reschedule_Reason__c = 'No Show'
        );

        insert appointment;

        Test.startTest();
        List<Event> appointments = OpportunitySalesReportingController.getAppointments(opportunity.Id);
        Test.stopTest();

        System.assertEquals(appointments.size(), 1);
    }

    @isTest static void getQuotes() {
        Opportunity opportunity = configureOpportunity();

        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = opportunity.Id,
            Finance__c = False
        );

        insert quote;

        Test.startTest();
        List<Quote> quotes = OpportunitySalesReportingController.getQuotes(opportunity.Id);
        Test.stopTest();

        System.assertEquals(quotes.size(), 1);
    }

    @isTest static void getAppointmentStatusPicklistValues() {
        Test.startTest();
        Map<String, String> appointmentStatusPicklistValues = OpportunitySalesReportingController.getAppointmentStatusPicklistValues();
        Test.stopTest();

        System.assert(appointmentStatusPicklistValues.size() > 0);
    }

    @isTest static void getQuoteRoofAgePicklistValues() {
        Test.startTest();
        Map<String, String> quoteRoofAgePicklistValues = OpportunitySalesReportingController.getQuoteRoofAgePicklistValues();
        Test.stopTest();

        System.assert(quoteRoofAgePicklistValues.size() > 0);
    }

    @isTest static void getQuoteShingleLayersPicklistValues() {
        Test.startTest();
        Map<String, String> quoteShingleLayersPicklistValues = OpportunitySalesReportingController.getQuoteShingleLayersPicklistValues();
        Test.stopTest();

        System.assert(quoteShingleLayersPicklistValues.size() > 0);
    }

    @isTest static void getQuoteFinanceTypePicklistValues() {
        Test.startTest();
        Map<String, String> quoteFinanceTypePicklistValues = OpportunitySalesReportingController.getQuoteFinanceTypePicklistValues();
        Test.stopTest();

        System.assert(quoteFinanceTypePicklistValues.size() > 0);
    }

    @isTest static void reportSaleIncomplete() {
		Opportunity opportunity = configureOpportunity();

        Event appointment = new Event(
            StartDateTime = System.Today(),
            Appointment_Status__c = 'Confirmed',
            Appointment_Notes__c = 'Test Notes',
            WhatId = opportunity.Id,
            DurationInMinutes = 60,
            Type = 'Meeting'
        );

        insert appointment;
        
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = opportunity.Id,
            Finance__c = False
        );

        insert quote;
        
        Map<String, Object> appointmentUpdates = new Map<String, Object>();
        appointmentUpdates.put('Appointment_Status__c', 'Cancelled');
        appointmentUpdates.put('Appointment_Notes__c', 'Test notes');
        
        
        Map<String, Object> quoteUpdates = new Map<String, Object>();
        quoteUpdates.put('Notes_from_Sales_Rep__c', 'Test Notes');
        quoteUpdates.put('Roof_age__c', '0-4 years');
        quoteUpdates.put('Layers_of_shingles__c', '2');
        
        Test.startTest();
        OpportunitySalesReportingController.reportSaleIncomplete(opportunity.Id, quote.Id, appointment.Id, appointmentUpdates, quoteUpdates);
        List<Event> appointments = OpportunitySalesReportingController.getAppointments(opportunity.Id);
        List<Quote> quotes = OpportunitySalesReportingController.getQuotes(opportunity.Id);
        Test.stopTest();
        
        Event updatedAppointment = appointments.get(0);
        Quote updatedQuote = quotes.get(0);
        
        System.assertEquals(updatedAppointment.Id, appointment.Id);
        System.assertEquals(updatedAppointment.Appointment_Status__c, 'Cancelled');
        
        System.assertEquals(updatedQuote.Id, quote.Id);
        System.assertEquals(updatedQuote.Status, 'Accepted');
    }

    @isTest static void reportSaleComplete() {
		Opportunity opportunity = configureOpportunity();

        Event appointment = new Event(
            StartDateTime = System.Today(),
            Appointment_Status__c = 'Confirmed',
            Appointment_Notes__c = 'Test Notes',
            WhatId = opportunity.Id,
            DurationInMinutes = 60,
            Type = 'Meeting'
        );

        insert appointment;
        
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = opportunity.Id,
            Finance__c = False
        );

        insert quote;
        
        Map<String, Object> appointmentUpdates = new Map<String, Object>();
        appointmentUpdates.put('Appointment_Status__c', 'Completed');
        appointmentUpdates.put('Appointment_Notes__c', 'Test notes');
        
        Test.startTest();
        OpportunitySalesReportingController.reportSaleComplete(opportunity.Id, appointment.Id, appointmentUpdates);
        List<Event> appointments = OpportunitySalesReportingController.getAppointments(opportunity.Id);
        List<Quote> quotes = OpportunitySalesReportingController.getQuotes(opportunity.Id);
        Test.stopTest();
        
        Event updatedAppointment = appointments.get(0);
        Quote updatedQuote = quotes.get(0);
        
        System.assertEquals(updatedAppointment.Id, appointment.Id);
        System.assertEquals(updatedAppointment.Appointment_Status__c, 'Completed');
        
        System.assertEquals(updatedQuote.Id, quote.Id);
        System.assertEquals(updatedQuote.Status, 'Presented');
    }

    // @isTest static void updateAppointment() {

    // }

    // @isTest static void updateQuote() {

    // }

    // @isTest static void updateOpportunity() {

    // }
}