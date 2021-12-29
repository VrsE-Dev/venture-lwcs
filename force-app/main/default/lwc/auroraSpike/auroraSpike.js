/* eslint-disable array-callback-return */
/* eslint-disable no-else-return */
/* eslint-disable no-console */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { updateRecord } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import getPVModule from '@salesforce/apex/AuroraSpikeController.getPVModule';
import getProjectDesigns from '@salesforce/apex/AuroraSpikeController.getProjectDesigns';
import getDesignSummary from '@salesforce/apex/AuroraSpikeController.getDesignSummary';
import upsertPVSystem from '@salesforce/apex/AuroraSpikeController.upsertPVSystem';

import QUOTE_ID from '@salesforce/schema/Quote.Id';
import QUOTE_OPPORTUNITID from '@salesforce/schema/Quote.OpportunityId';
import QUOTE_ACCOUNTID from '@salesforce/schema/Quote.AccountId';
import QUOTE_AURORA_PROJECT_ID from '@salesforce/schema/Quote.Aurora_Project_Id__c';
import QUOTE_SYSTEM from '@salesforce/schema/Quote.System__c';
import QUOTE_AURORA_PRODUCTION from '@salesforce/schema/Quote.Production_Override__c';

import PV_SYSTEM_PV_MODULES from '@salesforce/schema/PV_System__c.PV_Modules__c';
import PV_SYSTEM_QUOTE from '@salesforce/schema/PV_System__c.Quote__c';
import PV_SYSTEM_ACCOUNT from '@salesforce/schema/PV_System__c.Account__c';
import PV_SYSTEM_STATUS from '@salesforce/schema/PV_System__c.Status__c';

import PV_SYSTEM_INVERTER from '@salesforce/schema/PV_SYSTEM__c.Inverter__c';

import PV_ARRAY from '@salesforce/schema/PV_Array__c';
import PV_ARRAY_PANEL_WATTAGE from '@salesforce/schema/PV_Array__c.Panel_Wattage__c';
import PV_ARRAY_NUMBER_OF_PANELS from '@salesforce/schema/PV_Array__c.Number_of_Panels__c';
import PV_ARRAY_SELECTED_EQUIPMENT from '@salesforce/schema/PV_Array__c.Selected_Equipment__c';
import PV_ARRAY_TSRF from '@salesforce/schema/PV_Array__c.TSRF__c';
import PV_ARRAY_PV_SYSTEM from '@salesforce/schema/PV_Array__c.PV_System__c';
import PV_ARRAY_AZIMUTH from '@salesforce/schema/PV_Array__c.Azimuth__c';
import PV_ARRAY_TILT from '@salesforce/schema/PV_Array__c.Tilt__c';

export default class AuroraSpike extends NavigationMixin(LightningElement) {
    @track site;

    @track projectDesignOverview;
    @track designSummary;
    @track inverter = undefined;
    @track validArrays;

    @track noAuroraIdOnQuoteError = false;
    @track noArrayError = false;
    @track saveError = false;
    @track getDesignError  = false;
    @track invalidDesignSummary = true;
    @track validDesignSummary = false;
    @track loadingDesignSummary = false;
    @track hasInverter = false;
    @track saveSuccess = false;
    @track disabled = false;
    
    @track pvSystemUrl;
    @track pvSystemPageRef;
    
    @track selectedPVModule;
    @track inverter;

    @api recordId;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: [
                QUOTE_ID,
                QUOTE_OPPORTUNITID,
                QUOTE_ACCOUNTID,
                QUOTE_AURORA_PROJECT_ID
            ]
        }
    )
    getQuote({error, data}) {
        if (data) {
            console.log('data.fields:');
            console.log(JSON.stringify(data.fields));

            this.quote = {};
            Object.keys(data.fields).map((v, k) => {
                this.quote[v] = data.fields[v].value;
            });

            console.log('Aurora Spike Converted Quote:');
            console.log(JSON.stringify(this.quote, undefined, 2));

            if(!this.quote.Aurora_Project_Id__c) {
                console.log('quote has no aurora id');
                this.loadingDesignSummary = true;
                this.noAuroraIdOnQuoteError = true;
            }
        } else if (error) {
            console.log('Error getting quote data:');
            console.log(JSON.stringify(error, undefined, 2));
        }
    }

    async getDesignSummary() {
        this.loadingDesignSummary = true;
        this.invalidDesignSummary = true;
        this.validDesignSummary   = false;
        this.noArrayError = false;
        this.getDesignError = false;
        this.hasInverter = false;
        this.inverter = undefined;

        console.log('this.quote.Aurora_Project_Id__c:');
        console.log(this.quote.Aurora_Project_Id__c);

        try {
            const unparsedProjectDesigns = await getProjectDesigns({projectId: this.quote.Aurora_Project_Id__c});
            
            console.log('Project designs---');
            let projectDesigns = JSON.parse(unparsedProjectDesigns);
            console.log(JSON.stringify(projectDesigns, undefined, 2));

            if(projectDesigns.designs && projectDesigns.designs.length > 0) {
                //Get specific design id
                this.projectDesignOverview = projectDesigns.designs[0];

                const unParsedDesignSummary = await getDesignSummary({designId: this.projectDesignOverview.id});
                this.designSummary = JSON.parse(unParsedDesignSummary);
                console.log('Design summary---');
                console.log(JSON.stringify(this.designSummary, undefined, 2));

                // map design summary arrays to pv arrays
                if(this.designSummary?.design?.arrays && this.designSummary?.design?.arrays.length > 0) {
                    this.validArrays = this.designSummary.design.arrays
                        .filter(pvArray => pvArray.shading && pvArray.shading.total_solar_resource_fraction && pvArray.shading.total_solar_resource_fraction.annual)
        
                    if(this.validArrays.length > 0) {
                        console.log('Getting PV Module for:');
                        console.log(JSON.stringify(this.validArrays[0].module, undefined, 2));
                        this.selectedPVModule = await getPVModule({auroraPanelName: this.validArrays[0].module.name});
                        console.log('Got PV Module:');
                        console.log(JSON.stringify(this.selectedPVModule, undefined, 2));

                        if (this.designSummary?.design?.string_inverters && this.designSummary?.design?.string_inverters.length > 0) {
                            this.hasInverter = true;
                            this.inverter = this.designSummary?.design?.string_inverters[0].name;
                        }

                        this.invalidDesignSummary = false;
                        this.validDesignSummary = true;
                        this.loadingDesignSummary = false;
                    } else {
                        throw new Error('Design summary invalid - Check that irradiance has been run on design');
                    }
                } else {
                    this.noArrayError = true;
                    throw new Error(`Design summary invalid - See message for details`);
                }
            } else {
                throw new Error('Design summary invalid - Found no designs');
            }
        } catch (e) {
            console.log(e);
            this.getDesignError = true;
            this.loadingDesignSummary = false;
            const msg = e.body && e.body.message ? JSON.stringify(e.body.message, undefined, 2) : e.message;
            this.showToast('error', 'Error getting design:' + msg);
        }
    }

    async save() {
        this.disabled = true;
        this.saveSuccess = false;
        console.log('save kicked off');
        console.log(JSON.stringify(this.quote, undefined, 2));

        try {
            const pvSystemFields = {};
            pvSystemFields[PV_SYSTEM_PV_MODULES.fieldApiName]       = this.selectedPVModule.Id;
            pvSystemFields[PV_SYSTEM_QUOTE.fieldApiName]            = this.recordId;
            pvSystemFields[PV_SYSTEM_ACCOUNT.fieldApiName]          = this.quote.AccountId;
            pvSystemFields[PV_SYSTEM_STATUS.fieldApiName]           = 'Proposed';
            pvSystemFields[PV_SYSTEM_AURORA_INVERTER.fieldApiName]  = this.inverter;

            if (this.hasInverter) {
                pvSystemFields[PV_SYSTEM_INVERTER.fieldApiName] = this.inverter;
            }

            console.log('PV System Fields');
            console.log(JSON.stringify(pvSystemFields, undefined, 2));

            let pvSystemId = await upsertPVSystem({
                quoteId: this.recordId,
                changes: pvSystemFields
            });

            console.log('PVSYSTEMID:', pvSystemId);

            let quoteFields = {};
            quoteFields[QUOTE_ID.fieldApiName] = this.recordId;
            quoteFields[QUOTE_SYSTEM.fieldApiName] = pvSystemId
            quoteFields[QUOTE_AURORA_PRODUCTION.fieldApiName] = this.designSummary.design.energy_production.annual.toString();
            await updateRecord({fields: quoteFields});

            console.log(this.designSummary.design.arrays);
            console.log(this.designSummary.design.arrays[0].module);
            // loop through design summary arrays
            await this.designSummary.design.arrays
                .filter(pvArray => {
                    console.log(JSON.stringify(pvArray, undefined, 2)); 
                    return pvArray.module.count > 0;
                })
                .forEach(async pvArray => {
                    console.log('looping though design summary arrays');
   
                    const pvArrayFields = {};
                    pvArrayFields[PV_ARRAY_AZIMUTH.fieldApiName]            = pvArray.azimuth;
                    pvArrayFields[PV_ARRAY_TILT.fieldApiName]               = pvArray.pitch;
                    pvArrayFields[PV_ARRAY_NUMBER_OF_PANELS.fieldApiName]   = pvArray.module.count;
                    pvArrayFields[PV_ARRAY_PANEL_WATTAGE.fieldApiName]      = pvArray.module.rating_stc;
                    pvArrayFields[PV_ARRAY_TSRF.fieldApiName]               = pvArray.shading.total_solar_resource_fraction.annual;
                    pvArrayFields[PV_ARRAY_SELECTED_EQUIPMENT.fieldApiName] = this.selectedEquipment ? this.selectedEquipment.Id : undefined;
                    pvArrayFields[PV_ARRAY_PV_SYSTEM.fieldApiName]          = pvSystemId;

                    console.log('creating PV array record:');
                    console.log('apiName:', PV_ARRAY.objectApiName);
                    console.log('fields:', JSON.stringify(pvArrayFields, undefined, 2));
                    
                    await createRecord({
                        apiName: PV_ARRAY.objectApiName,
                        fields: pvArrayFields
                    });

                });

            console.log('completed all saving!!!!!!!!');

            this.showToast('success', 'Successfully saved aurora design information');

            this.pvSystemPageRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: pvSystemId,
                    objectApiName: 'PV_System__c',
                    actionName: 'view'
                }
            };
            
            console.log('pvSystemPageRef:');
            console.log(JSON.stringify(this.pvSystemPageRef, undefined, 2));

            this[NavigationMixin.GenerateUrl](this.pvSystemPageRef)
                .then(url => { 
                    this.pvSystemUrl = url; 
                    console.log(this.pvSystemUrl);
                })
                .catch(e => {
                    console.log('error trying to create navigation mixin:');
                    console.log(JSON.stringify(e, undefined, 2));
                })

            this.saveSuccess = true;
            this.disabled = false;

            getRecordNotifyChange([{
                recordId: this.recordId
            }]);
        } catch (e) {
            console.log('error from inside aurora spike save:');
            console.log(JSON.stringify(e, undefined, 2));
            this.saveError = true;
            this.disabled = false;

            this.showToast('error', e);
        }
    }

    showToast(variant, message) {
        const toast = new ShowToastEvent({
            title: variant.charAt(0).toUpperCase() + variant.slice(1),
            message,
            variant
        })
        this.dispatchEvent(toast);
    }

    handlePvSystemRedirect(evt) {
        // Stop the event's default behavior.
        // Stop the event from bubbling up in the DOM.
        evt.preventDefault();
        evt.stopPropagation();
        // Navigate to the Account Home page.
        this[NavigationMixin.Navigate](this.pvSystemPageRef);
    }
}
