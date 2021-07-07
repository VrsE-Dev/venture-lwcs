import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import createNewAuroraProject from '@salesforce/apex/AuroraProjectSiteButtonController.createAuroraProject';

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

    async createNewAuroraProject(){
        await createNewAuroraProject(this.site.Id, this.site.AccountId);
    }
}