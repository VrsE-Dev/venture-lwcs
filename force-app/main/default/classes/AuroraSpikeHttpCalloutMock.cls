global class AuroraSpikeHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        /// Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals(req.getEndpoint().contains('api-sandbox.aurorasolar.com/v2/tenants'), true);
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        System.debug(req.getEndpoint());
        
        if (req.getEndpoint().contains('summary')) {
            // Design Summary
            res.setBody('{"design": {"design_id": "204a9559-de84-4c75-a971-1f7b4abd991e","project_id": "a4b2b36a-2edf-4d78-aadc-a57b4767aef2","arrays": [{    "module": {        "id": "7545b2cc-0585-40fb-8eaf-2d475fa19d8f",        "name": "LG360Q1C-A5",        "manufacturer": "LG Electronics Inc.",        "rating_stc": 360,        "orientation": "portrait",        "count": 22    },    "strings": {        "count": 1    },    "azimuth": 75.8,    "pitch": 1.33,    "configuration": "string inverter",    "string_inverter": {        "index": 1    },    "face": 1,    "size": 7920}]}}');

        } else if(req.getEndpoint().contains('projects')) {
            // Project designs
            res.setBody('{"designs": [{"id": "204a9559-de84-4c75-a971-1f7b4abd991e","external_provider_id": null,"name": "Test Design","system_size": 65160.0,"system_size_stc": 65160.0,"system_size_ptc": 61105.6,"system_size_ac": 24000.0}]}');
        }
        
        return res;
    }
}