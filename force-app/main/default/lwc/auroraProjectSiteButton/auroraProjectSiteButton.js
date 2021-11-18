import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import createAuroraProject from '@salesforce/apex/AuroraProjectSiteButtonController.createAuroraProject';
import getAuroraSettings   from '@salesforce/apex/AuroraProjectSiteButtonController.getAuroraSettings';

import SITE_ID from '@salesforce/schema/Site__c.Id';
import SITE_ACCOUNT from '@salesforce/schema/Site__c.Account__c';
import SITE_AURORA_PROJECT_ID from '@salesforce/schema/Site__c.Aurora_Project_Id__c';

export default class AuroraProjectSiteButton extends NavigationMixin(LightningElement) {
    @track site;
    @api recordId;

    @track hasAuroraProject = false;
    @track auroraSettings;

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
    async getSite({error, data}) {
        if (data) {
            console.log('data.fields:');
            console.log(JSON.stringify(data.fields));

            this.site = {};
            Object.keys(data.fields).map((v, k) => {
                this.site[v] = data.fields[v].value;
            });

            console.log('Site Aurora System Design Converted site:');
            console.log(JSON.stringify(this.site, undefined, 2));

            if(this.site.Aurora_Project_Id__c) {
                console.log('site has aurora id');
                this.hasAuroraProject = true;
            }

            this.auroraSettings = await getAuroraSettings();
        } else if (error) {
            console.log('Error getting quote data:');
            console.log(JSON.stringify(error, undefined, 2));
        }
    }

    async createNewAuroraProject(){
        try{
            console.log("Create ");
            console.log(this.site.Id);
            console.log(this.site.Account__c);
            const auroraResponse = await createAuroraProject({siteId: this.site.Id, accountId: this.site.Account__c});

            console.log('Aurora response:', auroraResponse);
            window.open(`${this.auroraSettings.Dashboard_URL__c}/projects/${auroraResponse?.project?.id}`, '_blank');

            getRecordNotifyChange([{
                recordId: this.recordId
            }]);
        }
        catch(e) {
            console.log('error from inside aurora project button save:');
            console.log(JSON.stringify(e, undefined, 2));
            this.saveError = true;
            this.disabled = false;
        }
    }
}