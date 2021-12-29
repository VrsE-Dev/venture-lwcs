import { getRecord } from 'lightning/uiRecordApi';

import { parseRecord } from 'c/common-utils';

export default class OpportunitySalesReporting {
    opportunity; 

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
            void this.getAppointments();
        } else if (error) {
            console.error('Error getting opportunity data:');
            console.error(JSON.stringify(error, undefined, 2));
        }
    }

    async getAppointments() {
        // call to get appointments from service
        // soql query: SELECT WhoId, Type, WhatId, StartDateTime FROM Event WHERE WhatId = '0066t000002Y3o3AAC' ORDER BY StartDateTime DESC 
    }

}