/* eslint-disable no-await-in-loop */
/* eslint-disable guard-for-in */
/* eslint-disable no-unused-expressions */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import getQuotes from '@salesforce/apex/OpportunitySalesReportingController.getQuotes';
import getQuoteRoofAgePicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getQuoteRoofAgePicklistValues';
import getQuoteShingleLayersPicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getQuoteShingleLayersPicklistValues';
import getQuoteFinanceTypePicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getQuoteFinanceTypePicklistValues';
import getAppointments from '@salesforce/apex/OpportunitySalesReportingController.getAppointments';
import getAppointmentStatusPicklistValues from '@salesforce/apex/OpportunitySalesReportingController.getAppointmentStatusPicklistValues';
import reportSaleIncomplete from '@salesforce/apex/OpportunitySalesReportingController.reportSaleIncomplete';
import reportSaleComplete from '@salesforce/apex/OpportunitySalesReportingController.reportSaleComplete';

import OPPORTUNITY_ID from '@salesforce/schema/Opportunity.Id';
import QUOTE_NOTES_FROM_SALES_REP from '@salesforce/schema/Quote.Notes_from_Sales_Rep__c';
import QUOTE_ROOF_AGE from '@salesforce/schema/Quote.Roof_age__c';
import QUOTE_LAYERS_OF_SHINGLES from '@salesforce/schema/Quote.Layers_of_shingles__c';
import QUOTE_ACCEPTED_FINANCE_TYPE from '@salesforce/schema/Quote.Accepted_Finance_Type__c'
import QUOTE_STATUS from '@salesforce/schema/Quoote.Status';

import APPOINTMENT_STATUS from '@salesforce/schema/Event.Appointment_Status__c';
import APPOINTMENT_NOTES from '@salesforce/schema/Event.Notes__c';
import APPOINTMENT_REASON_NOT_MOVING_FORWARD from '@salesforce/schema/Event.Appointment_Reason_Not_Moving_Forward__c';

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
    }, {
        id: 3,
        isFourth: true,
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

    quoteFinanceTypePicklistValues;
    quoteRoofAgePicklistValues;
    quoteShingleLayersPicklistValues;
    quoteColumns;

    @track loading = false;

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
        const appointmentStatusPicklistValues = await getAppointmentStatusPicklistValues();
        console.log('picklistValues:');
        console.log(JSON.stringify(appointmentStatusPicklistValues, undefined, 2));

        this.appointmentStatusPicklistValues =  Object.keys(appointmentStatusPicklistValues).map(key => {
            return {
                label: key,
                value: key
            }
        });

        this.appointmentColumns = [
            { 
                label: 'Date', 
                fieldName: 'StartDateTime',
                type: "date",
                typeAttributes: {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }
            },
            { label: 'Status', fieldName: 'Appointment_Status__c' },
            { label: 'Subject', fieldName: 'Subject' }
        ];

        this.appointments = await getAppointments({opportunityId: this.opportunity.Id});
        console.log(JSON.stringify(this.appointments, undefined, 2));
    }
    
    async getQuotes() {
        const quoteRoofAgePicklistValues = await getQuoteRoofAgePicklistValues();
        console.log('quoteRoofAgePicklistValues:');
        console.log(JSON.stringify(quoteRoofAgePicklistValues, undefined, 2));

        this.quoteRoofAgePicklistValues =  Object.keys(quoteRoofAgePicklistValues).map(key => {
            return {
                label: key,
                value: key
            }
        });

        const quoteShingleLayersPicklistValues = await getQuoteShingleLayersPicklistValues();
        console.log('quoteShingleLayersPicklistValues:');
        console.log(JSON.stringify(quoteShingleLayersPicklistValues, undefined, 2));

        this.quoteShingleLayersPicklistValues =  Object.keys(quoteShingleLayersPicklistValues).map(key => {
            return {
                label: key,
                value: key
            }
        });

        const quoteFinanceTypePicklistValues = await getQuoteFinanceTypePicklistValues();
        console.log('quoteFinanceTypePicklistValues:');
        console.log(JSON.stringify(quoteFinanceTypePicklistValues, undefined, 2));

        this.quoteFinanceTypePicklistValues =  Object.keys(quoteFinanceTypePicklistValues).map(key => {
            return {
                label: key,
                value: key
            }
        });

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

    get isAppointmentStatusCompletedSelected() {
        return this.appointmentSelected.Appointment_Status__c === 'Completed'
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
        this.loading = false;
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

    handleAppointmentSelection(event) {
        event.stopPropagation();
        console.log('Handle appointment selection:', JSON.stringify(event, undefined, 2));
        
        this.setStepValidity(false);

        const selectedRows = [...event.detail.selectedRows];
        if (selectedRows.length === 1) {
            this.appointmentSelected = Object.assign({}, selectedRows[0]);
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
        this.appointmentSelected.Notes__c = this.template.querySelector('.resultNotes').value;
        this.incrementStepCurrent();
    }

    handleQuoteSelection(event){
        event.stopPropagation();
        console.log('Handle quote selection:', JSON.stringify(event, undefined, 2));

        this.setStepValidity(false);
        
        const selectedRows = [...event.detail.selectedRows];
        if (selectedRows.length === 1) {
            this.quoteSelected = selectedRows[0];
            this.setStepValidity(true);
        }
    }

    saveQuoteSelection() {
        this.checkQuoteValidity();
        this.incrementStepCurrent();
    }

    handleQuoteContractNotesChanged(event) {
        console.log('Handle Quote contract notes changed:', JSON.stringify(event.detail.value, undefined, 2));
        
        this.quoteSelected.Notes_from_Sales_Rep__c = event?.detail?.value;
        this.checkQuoteValidity();
    }

    handleQuoteRoofAgePicklistChanged(event) {
        console.log('Handle Quote Roof Age Picklist Changed:', JSON.stringify(event.detail.value, undefined, 2));

        this.quoteSelected.Roof_age__c = event?.detail?.value;
        this.checkQuoteValidity();
    }

    handleQuoteShingleLayersPicklistChanged(event) {
        console.log('Handle Quote Shingle Layers Picklist Changed:', JSON.stringify(event.detail.value, undefined, 2));

        this.quoteSelected.Layers_of_shingles__c = event?.detail?.value;
        this.checkQuoteValidity();
    }

    handleQuoteFinanceTypePicklistChanged(event) {
        console.log('Handle Quote Shingle Layers Picklist Changed:', JSON.stringify(event.detail.value, undefined, 2));

        this.quoteSelected.Accepted_Finance_Type__c = event?.detail?.value;
        this.checkQuoteValidity();
    }

    checkQuoteValidity() {
        this.setStepValidity(false);

        if (
            this.quoteSelected.Notes_from_Sales_Rep__c && 
            this.quoteSelected.Roof_age__c &&
            this.quoteSelected.Layers_of_shingles__c &&
            this.quoteSelected.Accepted_Finance_Type__c
        ) {
                this.setStepValidity(true);
        }
    }

    async saveComplete() {
        const appointmentUpdates = {};
        appointmentUpdates[APPOINTMENT_STATUS.fieldApiName] = this.appointmentSelected.Appointment_Status__c;
        appointmentUpdates[APPOINTMENT_NOTES.fieldApiName] = this.appointmentSelected.Notes__c;
        appointmentUpdates[APPOINTMENT_REASON_NOT_MOVING_FORWARD.fieldApiName] = this.appointmentSelected.Reason_Not_Moving_Forward__c;

        try {
            this.loading = true;

            console.log(JSON.stringify({
                opportunityId: this.opportunity.Id,
                quoteId: this.quoteSelected.Id,
                appointmentId: this.appointmentSelected.Id,
                appointmentUpdates,
            }, undefined, 2));

            await reportSaleComplete({
                opportunityId: this.opportunity.Id,
                appointmentId: this.appointmentSelected.Id,
                appointmentUpdates
            });

            this.dispatchEvent(showToast('success', 'Your sale has been recorded!'));
            this.cancel();
        } catch(e) {
            this.loading = false;
            this.createErrorMsg(e)
        }
    }

    async saveIncomplete() {
        const appointmentUpdates = {};
        appointmentUpdates[APPOINTMENT_STATUS.fieldApiName] = this.appointmentSelected.Appointment_Status__c;
        appointmentUpdates[APPOINTMENT_NOTES.fieldApiName] = this.appointmentSelected.Notes__c;

        const quoteUpdates = {};
        quoteUpdates[QUOTE_NOTES_FROM_SALES_REP.fieldApiName] = this.quoteSelected.Notes_from_Sales_Rep__c;
        quoteUpdates[QUOTE_ROOF_AGE.fieldApiName] = this.quoteSelected.Roof_age__c;
        quoteUpdates[QUOTE_LAYERS_OF_SHINGLES.fieldApiName] = this.quoteSelected.Layers_of_shingles__c;
        quoteUpdates[QUOTE_ACCEPTED_FINANCE_TYPE.fieldApiName] = this.quoteSelected.Accepted_Finance_Type__c;

        try {
            this.loading = true;

            console.log(JSON.stringify({
                opportunityId: this.opportunity.Id,
                quoteId: this.quoteSelected.Id,
                appointmentId: this.appointmentSelected.Id,
                appointmentUpdates,
                quoteUpdates
            }, undefined, 2));

            await reportSaleIncomplete({
                opportunityId: this.opportunity.Id,
                quoteId: this.quoteSelected.Id,
                appointmentId: this.appointmentSelected.Id,
                appointmentUpdates,
                quoteUpdates
            });

            this.dispatchEvent(showToast('success', 'Your sale has been recorded!'));
            this.cancel();
        } catch (e) {
            this.loading = false;
            this.createErrorMsg(e)
        }
    }

    createErrorMsg(e) {
        console.log(JSON.stringify(e, undefined, 2));

        let errorMsg = '';
        if (e?.body?.fieldErrors) {
            Object.keys(e.body.fieldErrors).forEach(fieldKey => {
                const fieldKeyErrors = e.body.fieldErrors[fieldKey];
                fieldKeyErrors.forEach(fieldKeyError => {
                    if (fieldKeyError.message) {
                        errorMsg += fieldKeyError.message + '\n'; 
                    }
                });
            });
        }

        if (e?.body?.pageErrors) {
            const pageErrors = e.body.pageErrors;
            pageErrors.forEach(pageError => {
                if (pageError.message) {
                    errorMsg += pageError.message + '\n' 
                }
            });
        }

        if (errorMsg === '') {
            errorMsg = JSON.stringify(e, undefined, 2);
        }

        this.dispatchEvent(showToast('error', `Error recording sale: \n ${errorMsg}`));
    }
}
