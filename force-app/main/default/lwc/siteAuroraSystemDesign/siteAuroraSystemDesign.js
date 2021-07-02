/* eslint-disable array-callback-return */
/* eslint-disable no-else-return */
/* eslint-disable no-console */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import getProjectDesigns from '@salesforce/apex/AuroraSpikeController.getProjectDesigns';
import getDesignSummary from '@salesforce/apex/AuroraSpikeController.getDesignSummary';

import getAllowedArrays from '@salesforce/apex/SystemOptimizerController.getAllowedArrays';

import ALLOWED_ARRAY_NAME from '@salesforce/schema/Allowed_Array__c.Name';
import ALLOWED_ARRAY_NUMBER_OF_PANELS__C  from '@salesforce/schema/Allowed_Array__c.Number_of_Panels__c';
import ALLOWED_ARRAY_SITE__C from '@salesforce/schema/Allowed_Array__c.Site__c';
import ALLOWED_ARRAY_TSRF__C from '@salesforce/schema/Allowed_Array__c.TSRF__c';

import SITE_ID from '@salesforce/schema/Site.Id';
import SITE_ACCOUNT_ID from '@salesforce/schema/Site.AccountId';
import SITE_AURORA_PROJECT_ID from '@salesforce/schema/Site.Aurora_Project_Id__c';

export default class AuroraSpike extends NavigationMixin(LightningElement) {
    @track site;

    @track projectDesignOverview;
    @track designSummary;
    @track validArrays;
    @track existingAllowedArrays;

    @track noAuroraIdOnQuoteError = false;
    @track noArrayError = false;
    @track saveError = false;
    @track getDesignError  = false;
    @track invalidDesignSummary = true;
    @track validDesignSummary = false;
    @track loadingDesignSummary = false;
    @track saveSuccess = false;
    @track disabled = false;
    
    @track pvSystemUrl;
    @track pvSystemPageRef;
    
    @track selectedPVModule;

    @api recordId;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: [
                SITE_ID,
                SITE_ACCOUNT_ID,
                SITE_AURORA_PROJECT_ID
            ]
        }
    )
    getQuote({error, data}) {
        if (data) {
            console.log('data.fields:');
            console.log(JSON.stringify(data.fields));

            this.site = {};
            Object.keys(data.fields).map((v, k) => {
                this.site[v] = data.fields[v].value;
            });

            console.log('Site Aurora System Design Converted site:');
            console.log(JSON.stringify(this.site, undefined, 2));

            if(!this.site.Aurora_Project_Id__c) {
                console.log('site has no aurora id');
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

        console.log('this.site.Aurora_Project_Id__c:');
        console.log(this.site.Aurora_Project_Id__c);

        try {
            const unparsedProjectDesigns = await getProjectDesigns({projectId: this.site.Aurora_Project_Id__c});
            this.validateAuroraResponse(unparsedProjectDesigns);
            this.existingAllowedArrays = await this.getAllowedArrays(this.site.AccountId);
        
        } catch (e) {
            console.log(e);
            this.getDesignError = true;
            this.loadingDesignSummary = false;
            const msg = e.body && e.body.message ? JSON.stringify(e.body.message, undefined, 2) : e.message;
            this.showToast('error', 'Error getting design:' + msg);
        }
    }

    /**
     * Creates allowed arrays based off valid arrays design response
     */
    async createAllowedArrays() {
        this.validArrays.forEach(() => {
            // create allowable array
            let allowableArrayField = {};
            allowableArrayField[ALLOWED_ARRAY_NAME.fieldApiName] = pvArray.Array_Size__c;
            allowableArrayField[ALLOWED_ARRAY_NUMBER_OF_PANELS__C.fieldApiName] = pvArray.Number_of_Panels__c;
            allowableArrayField[ALLOWED_ARRAY_SITE__C.fieldApiName] = pvArray.Selected_Equipment__c;
            allowableArrayField[ALLOWED_ARRAY_TSRF__C.fieldApiName] = pvArray.TSRF__c;

            console.log('pvArray:');
            console.log(JSON.stringify(pvArrayFields, undefined, 2));
            // await createRecord({
            //     apiName: PV_ARRAY__C.objectApiName,
            //     fields: pvArrayFields
            // });
            this.showToast('success', `Successfully cloned pvArray ${pvArray.Id}`);
        });
    }
    /**
     * Deletes existing allowed arrays and calls function to
     * create allowed arrays
     */
    async overwriteAllowedArrays() { 
        this.existingAllowedArrays.forEach(() => {
            // delete existing arrays
        });

        await this.createAllowedArrays();
    }

    static validateAuroraResponse(unparsedProjectDesigns) {
        console.log('Project designs---');
        let projectDesigns = JSON.parse(unparsedProjectDesigns);
        console.log(JSON.stringify(projectDesigns, undefined, 2));

        if(projectDesigns.designs && projectDesigns.designs.length > 0) {
            //Get specific design id
            this.projectDesignOverview = projectDesigns.designs[0];

            const unParsedDesignSummary = getDesignSummary({designId: this.projectDesignOverview.id});
            this.designSummary = JSON.parse(unParsedDesignSummary);
            console.log('Design summary---');
            console.log(JSON.stringify(this.designSummary, undefined, 2));

            // map design summary arrays to pv arrays
            if(this.designSummary.design.arrays && this.designSummary.design.arrays.length > 0) {
                this.validArrays = this.designSummary.design.arrays
                    .filter(pvArray => pvArray.shading && pvArray.shading.total_solar_resource_fraction && pvArray.shading.total_solar_resource_fraction.annual)
    
                if(this.validArrays.length > 0) {
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
    }

    static getAllowedArrays(accountId) {
        try {
            let data = getAllowedArrays({
                accountId: accountId
            });

            console.log('got allowed arrays:');
            console.log(JSON.stringify(data));

            if (!data || data.length === 0) {
                data = undefined;
            }

            return data;
        } catch(e) {
            console.log('got error:', e);
            this.error = true;
        }
    }
}
