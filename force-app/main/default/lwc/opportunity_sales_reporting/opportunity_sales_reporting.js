/* eslint-disable no-await-in-loop */
/* eslint-disable guard-for-in */
/* eslint-disable no-unused-expressions */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
// import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import getQuotes from '@salesforce/apex/OpportunitySalesReportingController.getQuotes';
import getAppointments from '@salesforce/apex/OpportunitySalesReportingController.getAppointments';
import getAppointmentStatusPicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getAppointmentStatusPicklistValues';
import reportSale from '@salesforce/apex/OpportunitySalesReportingController.reportSale';

import OPPORTUNITY_ID from '@salesforce/schema/Opportunity.Id';
import APPOINTMENT_STATUS from '@salesforce/schema/Event.Appointment_Status__c';
import APPOINTMENT_NOTES from '@salesforce/schema/Event.Notes__c';

import { parseRecord, showToast } from 'c/common_utils';

export default class OpportunitySalesReporting extends LightningElement {
    @api recordId;

    @track currentStep = 1;
    @track steps = [{
        id: 0,
        isFirst: true,
        current: true,
        invalid: true,
    }, {
        id: 1,
        isSecond: true,
        current: false,
    }, {
        id: 2,
        isThird: true,
        current: false,
        invalid: true
    }];

    @track opportunity; 
    
    @track appointments = [];
    @track appointmentSelectedRows = [];
    @track appointmentSelected;
    appointmentStatusPicklistValues;
    appointmentColumns;
    appointmentMetadata;

    @track quotes = [];
    @track quoteSelected;
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

    async getAppointments() {
        const picklistValues = await getAppointmentStatusPicklistValues();
        console.log('picklistValues:');
        console.log(JSON.stringify(picklistValues, undefined, 2));

        this.appointmentStatusPicklistValues =  Object.keys(picklistValues).map(key => {
            return {
                label: key,
                value: key
            }
        });

        this.appointmentColumns = [
            { label: 'Date', fieldName: 'StartDateTime' },
            { label: 'Status', fieldName: 'Appointment_Status__c' }
        ];

        this.appointments = await getAppointments({opportunityId: this.opportunity.Id});
        console.log(JSON.stringify(this.appointments, undefined, 2));
    }
    
    async getQuotes() {
        this.quoteColumns = [
            { label: 'Name', fieldName: 'StartDateTime' },
            { label: 'Status', fieldName: 'Status', type: 'text' },
            { label: 'System', fieldName: 'System__c', type: 'text' },
            { label: 'Number of Panels', fieldName: 'Number_of_Panels__c', type: 'text' },
            { label: 'System Size', fieldName: 'System_Size__c', type: 'text' },
        ];

        this.quotes = await getQuotes({opportunityId: this.opportunity.Id});
        console.log('this.quotes:');
        console.log(JSON.stringify(this.quotes, undefined, 2));
    }

    incrementStepCurrent() {
        this.currentStep += 1;
        this.steps.forEach((step, index) => {
            step.current = index + 1 === this.currentStep ? true : false;
        });
    }

    setStepValidity(validity) {
        this.steps.forEach((step, index) => {
            step.invalid = index + 1 === this.currentStep ? !validity : step.invalid;
        });
    }

    cancel() {
        this.currentStep = 1;
        this.steps.forEach((step, index) => {
            step.current = index + 1 === this.currentStep ? true : false;
            step.invalid = true;
        });
        this.appointmentSelected = undefined;
        this.appointmentSelectedRows = [];
        this.quoteSelected = undefined;
        this.quoteSelectedRows = [];
    }

   
    // handleAppointmentCellChange(event) {
    //     this.updateDraftValues(event.detail.draftValues[0], this.appointmentDraftValues);
    //     console.log('this.appointmentDraftValues:', JSON.stringify(this.appointmentDraftValues, undefined, 2));
    // }

    // async handleAppointmentSave() {
    //     console.log('appointment draft data:', JSON.stringify(this.appointmentDraftValues, undefined, 2));
    //     for(let i = 0; i < this.appointmentDraftValues.length; i++) {
    //         const appointmentUpdate = this.appointmentDraftValues[i];
    //         console.log('appointmentUpdate:', JSON.stringify(appointmentUpdate, undefined, 2));
    //         const appointmentFields = {};

    //         appointmentFields[APPOINTMENT_STATUS.fieldApiName] = appointmentUpdate.Appointment_Status__c;
    //         appointmentFields[APPOINTMENT_NOTES.fieldApiName] = appointmentUpdate.Notes__c

    //         console.log('appointmentFields:', JSON.stringify(appointmentFields, undefined, 2));
    //         await updateAppointment({
    //             appointmentId: appointmentUpdate.Id,
    //             changes: appointmentFields
    //         });
    //     }
    // }

    handleAppointmentSelection(event) {
        event.stopPropagation();
        console.log('Handle appointment selection:', JSON.stringify(event, undefined, 2));
        
        this.setStepValidity(false);

        if (event.detail.selectedRows.length === 1) {
            this.appointmentSelected = event.detail.selectedRows[0];
            this.setStepValidity(true);
        } 
    }

    saveAppointmentSelection() {
        this.incrementStepCurrent();
    }

    handleAppointmentStatusPicklistChanged(event) {
        // event.stopPropagation();
        console.log('Handle Appointment Status Picklist Changed:', JSON.stringify(event.detail.value, undefined, 2));

        this.setStepValidity(false);

        if (event?.detail?.value) {
            this.appointmentSelected.Appointment_Status__c = event.detail.value;
            this.setStepValidity(true)
        }
    }

    saveAppointmentUpdate() {
        this.incrementStepCurrent();
    }

    handleQuoteSelection(event){
        event.stopPropagation();
        console.log('Handle quote selection:', JSON.stringify(event, undefined, 2));

        this.setStepValidity(false);
        
        if (event.detail.selectedRows.length === 1) {
            this.quoteSelected = event.detail.selectedRows[0];
            this.setStepValidity(true);
        }
    }

    async save() {
        const appointmentUpdates = {};
        appointmentUpdates[APPOINTMENT_STATUS.fieldApiName] = this.appointmentSelected.Appointment_Status__c;
        appointmentUpdates[APPOINTMENT_NOTES.fieldApiName] = this.appointmentSelected.Notes__c

        try {
            await reportSale({
                opportunityId: this.opportunity.Id,
                quoteId: this.quoteSelected.Id,
                appointmentId: this.appointmentSelected.Id,
                appointmentUpdates
            });

            this.dispatchEvent(showToast('success', 'Your sale has been recorded!'));
            this.cancel();
        } catch (e) {
            console.log(JSON.stringify(e, undefined, 2));
            this.dispatchEvent(showToast('error', `Error recording sale: ${JSON.stringify(e)}`));
        }
    }
}