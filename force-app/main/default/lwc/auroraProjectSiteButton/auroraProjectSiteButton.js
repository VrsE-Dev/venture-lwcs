import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import createNewAuroraProject from '@salesforce/apex/AuroraSpikeController.createAuroraProject';

import SITE_ID from '@salesforce/schema/Site.Id';
import SITE_ACCOUNTID from '@salesforce/schema/Site.AccountId';
import SITE_AURORA_PROJECT_ID from '@salesforce/schema/Site.Aurora_Project_Id__c';

export default class AuroraProjectSiteButton extends NavigationMixin(LightningElement) {
    @track site;
    @api recordId;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: [
                SITE_ID,
                SITE_ACCOUNTID,
                SITE_AURORA_PROJECT_ID
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

    async createNewAuroraProject(){
        await createNewAuroraProject(this.site.Id, this.site.AccountId);
    }
}