import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
// import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import getQuotes from '@salesforce/apex/OpportunitySalesReportingController.getQuotes';
import getAppointments from '@salesforce/apex/OpportunitySalesReportingController.getAppointments';
import getAppointmentStatusPicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getAppointmentStatusPicklistValues';

import OPPORTUNITY_ID from '@salesforce/schema/Opportunity.Id';
// import APPOINTMENT from '@salesforce/schema/Event';
// import APPOINTMENT_STATUS from '@salesforce/schema/Event.Appointment_Status__c';

import { parseRecord } from 'c/common_utils';

export default class OpportunitySalesReporting extends LightningElement {
    @api recordId;

    @track opportunity; 
    
    @track appointments;
    appointmentStatusPicklistValues;
    appointmentColumns;
    appointmentMetadata;

    @track quotes;
    quoteColumns;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: [
                OPPORTUNITY_ID
            ]
        }
    )
    async getOpportunity({error, data}) {
        console.log('getting opportunity');
        if (data) {
            console.log('parsing opportunity'); 
            this.opportunity = parseRecord(data);
            console.log('parsed opportunity:');
            console.log(JSON.stringify(this.opportunity, undefined, 2));

            await this.getAppointments();
            await this.getQuotes();
        } else if (error) {
            console.error('Error getting opportunity data:');
            console.error(JSON.stringify(error, undefined, 2));
        }
    }

    // @wire(getObjectInfo, { objectApiName: APPOINTMENT }) 
    // getAppointmentMetadata({error, data}) {
    //     console.log('getting appointment metadata');
    //     if (data) {
    //         console.log('appointment metadata:');
    //         console.log(JSON.stringify(data, undefined, 2));
    //         this.appointmentMetadata = data;
    //     }
    // }
    
    // @wire(
    //     getPicklistValues,
    //     {
    //         recordTypeId: '$appointmentMetadata.data.defaultRecordTypeId', 
    //         fieldApiName: APPOINTMENT_STATUS
    //     }
    // )
    // async getAppointmentStatusPicklistValues({error, data}) {
    //     if (data) {
    //         console.log('Appointment status picklist values:');
    //         console.log(JSON.stringify(data, undefined, 2));

    //         this.appointmentStatusPicklistValues = data;
    //         await this.getAppointments();
    //     } else if (error) {
    //         console.log('Error getting appointment status picklist values:');
    //         console.log(JSON.stringify(error, undefined, 2));
    //     }
    // }

    async getAppointments() {
        const picklistValues = await getAppointmentStatusPicklistValues();
        console.log('picklistValues:');
        console.log(JSON.stringify(picklistValues, undefined, 2));
        this.appointmentColumns = [
            { label: 'Date', fieldName: 'StartDateTime' },
            { 
                label: 'Status', 
                fieldName: 'Appointment_Status__c', 
                type: 'picklist',
                typeAttributes: {
                    placeholder: 'Change Status',
                    options: picklistValues,
                    value: { fieldName: picklistValues[0] },
                    context: { fieldName: 'Id' } 
                } 
            },
            { label: 'Notes', fieldName: 'Notes__c', type: 'text', editable: true },
        ];

        this.appointments = await getAppointments({opportunityId: this.opportunity.Id});
        console.log(this.appointments);
        // call to get appointments from service
        // soql query: SELECT WhoId, Type, WhatId, StartDateTime FROM Event WHERE WhatId = '0066t000002Y3o3AAC' ORDER BY StartDateTime DESC 
    }

    async getQuotes() {
        this.quoteColumns = [
            { label: 'Name', fieldName: 'StartDateTime' },
            { label: 'Status', fieldName: 'Status', type: 'text' },
            { label: 'System', fieldName: 'System__c', type: 'text' },
            { label: 'Number of Panels', fieldName: 'Number_of_Panels__c', type: 'text' },
            { label: 'System Size', fieldName: 'System_Size__c', type: 'text' },
        ];

        this.quotes = await getQuotes({opportunityId: this.opportunityId});
        console.log(this.quotes);
    }
}