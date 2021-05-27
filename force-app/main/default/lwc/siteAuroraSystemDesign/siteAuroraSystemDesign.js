/* eslint-disable array-callback-return */
/* eslint-disable no-else-return */
/* eslint-disable no-console */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord, getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getProjectDesigns from '@salesforce/apex/AuroraSpikeController.getProjectDesigns';
import getDesignSummary from '@salesforce/apex/AuroraSpikeController.getDesignSummary';

import getAllowedArrays from '@salesforce/apex/SiteAuroraSystemDesignController.getAllowedArrays';

import ALLOWED_ARRAY from '@salesforce/schema/Allowed_Array__c';
import ALLOWED_ARRAY_NAME from '@salesforce/schema/Allowed_Array__c.Name';
import ALLOWED_ARRAY_NUMBER_OF_PANELS__C  from '@salesforce/schema/Allowed_Array__c.Number_of_Panels__c';
import ALLOWED_ARRAY_SITE__C from '@salesforce/schema/Allowed_Array__c.Site__c';
import ALLOWED_ARRAY_TSRF__C from '@salesforce/schema/Allowed_Array__c.TSRF__c';

import SITE_ID from '@salesforce/schema/Site__c.Id';
import SITE_ACCOUNT_ID from '@salesforce/schema/Site__c.Account__c';
import SITE_AURORA_PROJECT_ID from '@salesforce/schema/Site__c.Aurora_Project_Id__c';

export default class SiteAuroraSystemDesign extends NavigationMixin(LightningElement) {
    @track site;

    @track projectDesignOverview;
    @track validArrays;
    @track existingAllowedArrays;

    @track noAuroraIdOnSiteError = false;
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
                this.noAuroraIdOnSiteError = true;
            }
        } else if (error) {
            console.log('Error getting quote data:');
            console.log(JSON.stringify(error, undefined, 2));
        }
    }

    async getAuroraProject() {
        this.loadingDesignSummary = true;
        this.invalidDesignSummary = true;
        this.validDesignSummary   = false;
        this.noArrayError = false;
        this.getDesignError = false;

        console.log('this.site.Aurora_Project_Id__c:');
        console.log(this.site.Aurora_Project_Id__c);

        try {
            this.projectDesignOverview = await this.getProjectDesignOverview();
            this.validArrays = await this.getProjectArrays(this.projectDesignOverview.id);
            this.existingAllowedArrays = await this.getAllowedArrays(this.site.Account__c);
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
        this.validArrays.forEach(async (pvArray) => {
            // create allowed array
            let allowedArrayFields = {};
            allowedArrayFields[ALLOWED_ARRAY_NAME.fieldApiName] = pvArray.Array_Size__c;
            allowedArrayFields[ALLOWED_ARRAY_NUMBER_OF_PANELS__C.fieldApiName] = pvArray.Number_of_Panels__c;
            allowedArrayFields[ALLOWED_ARRAY_SITE__C.fieldApiName] = pvArray.Selected_Equipment__c;
            allowedArrayFields[ALLOWED_ARRAY_TSRF__C.fieldApiName] = pvArray.TSRF__c;

            console.log('allowedArray:');
            console.log(JSON.stringify(allowedArrayFields, undefined, 2));
            await createRecord({
                apiName: ALLOWED_ARRAY.objectApiName,
                fields: allowedArrayFields
            });
            this.showToast('success', `Successfully created allowed array ${pvArray.Id}`);
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

    /**
     * Parses project design and validates it, returning design id if valid
     * throwing error otherwise
     * @returns design object
     */
    async getProjectDesignOverview() {
        const unparsedProjectDesigns = await getProjectDesigns({projectId: this.site.Aurora_Project_Id__c});
        const projectDesigns = JSON.parse(unparsedProjectDesigns);
        console.log('Project designs---');
        console.log(JSON.stringify(projectDesigns, undefined, 2));

        if(projectDesigns.designs && projectDesigns.designs.length > 0) {
            //Get specific design id
            return projectDesigns.designs[0];
        } else {
            throw new Error('Design summary invalid - Found no designs');
        }
    }

    /**
     * Grabs design summary and parses it for valid arrays
     * @param {number} projectDesignOverviewId 
     * @returns array object of valid project arrays
     */
    async getProjectArrays(projectDesignOverviewId) {
        const unParsedDesignSummary = await getDesignSummary({designId: projectDesignOverviewId});
        const designSummary = JSON.parse(unParsedDesignSummary);
        console.log('Design summary---');
        console.log(JSON.stringify(designSummary, undefined, 2));

        // map design summary arrays to pv arrays
        if(designSummary.design.arrays && designSummary.design.arrays.length > 0) {
            const validArrays = designSummary.design.arrays
                .filter(pvArray => pvArray.shading && pvArray.shading.total_solar_resource_fraction && pvArray.shading.total_solar_resource_fraction.annual)

            if(validArrays.length > 0) {
                this.invalidDesignSummary = false;
                this.validDesignSummary = true;
                this.loadingDesignSummary = false;
                return validArrays;
            } else {
                throw new Error('Design summary invalid - Check that irradiance has been run on design');
            }
        } else {
            this.noArrayError = true;
            throw new Error(`Design summary invalid - See message for details`);
        }
    }

    /**
     * Hits Apex class to grab allowed arrays and returns them
     * @param {string} accountId 
     * @returns array of allowed arrays
     */
    async getAllowedArrays(accountId) {
        try {
            let data = await getAllowedArrays({
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
            throw new Error('Allowed Arrays error - Error getting allowed arrays:', e);
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
}
