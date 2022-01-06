import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import APPOINTMENT from '@salesforce/schema/Event';
import APPOINTMENT_STATUS from '@salesforce/schema/Event.Appointment_Status__c';

import { parseRecord } from 'c/common_utils';

export default class OpportunitySalesReporting extends LightningElement {
    opportunity; 
    
    @track appointments;
    appointmentStatusPicklistValues;
    appointmentColumns;

    @track quotes;
    quoteColumns;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: []
        }
    )
    async getOpportunity({error, data}) {
    if (data) {
            this.opportunity = parseRecord(data);
            await this.getAppointments();
            await this.getQuotes();
        } else if (error) {
            console.error('Error getting opportunity data:');
            console.error(JSON.stringify(error, undefined, 2));
        }
    }

    @wire(getObjectInfo, { objectApiName: APPOINTMENT })
    appointmentMetadata

    @wire(
        getPicklistValues,
        {
            recordTypeId: '$appointmentMetadata.data.defaultRecordTypeId', 
            fieldApiName: APPOINTMENT_STATUS
        }
    )
    getAppointmentStatusPicklistValues({error, data}) {
        if (data) {
            console.log('Appointment status picklist values:');
            console.log(JSON.stringify(data, undefined, 2));

            this.appointmentStatusPicklistValues = data;
        } else if (error) {
            console.log('Error getting appointment status picklist values:');
            console.log(JSON.stringify(error, undefined, 2));
        }
    }

    async getAppointments() {
        this.appointmentColumns = [
            { label: 'Date', fieldName: 'StartDateTime' },
            { 
                label: 'Status', 
                fieldName: 'Appointment_Status__c', 
                type: 'picklist',
                typeAttributes: {
                    placeholder: 'Change Status',
                    options: this.appointmentStatusPicklistValues,
                    value: { fieldName: this.appointmentStatusPicklistValues[0] },
                    context: { fieldName: 'Id' } 
                } 
            },
            { label: 'Notes', fieldName: 'Notes__c', type: 'text', editable: true },
        ];

        this.appointments = await this.getAppointments({opportunityId: this.opportunity.Id});
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

        this.quotes = await this.getQuotes({opportunityId: this.opportunityId});
        console.log(this.quotes);
    }
}