import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import createNewAuroraProject from '@salesforce/apex/AuroraProjectSiteButtonController.createAuroraProject';

import SITE_ID from '@salesforce/schema/Site__c.Id';
import SITE_ACCOUNT from '@salesforce/schema/Site__c.Account__c';
import SITE_AURORA_PROJECT_ID from '@salesforce/schema/Site__c.Aurora_Project_Id__c';

export default class AuroraProjectSiteButton extends NavigationMixin(LightningElement) {
    @track site;
    @api recordId;

    @track loadingDesignSummary = false;
    @track noAuroraIdOnQuoteError = false;

    @wire(
        getRecord,
        {
            recordId: '$recordId',
            fields: [
                SITE_ID,
                SITE_ACCOUNT,
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

    async createNewAuroraProject(){
        await createNewAuroraProject(this.site.Id, this.site.Account.Id);
    }
}