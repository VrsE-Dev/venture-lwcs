({
    init: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var opportunityId = myPageRef.state.c__opportunityId;
        cmp.set("v.opportunityId", opportunityId);
    },

    onPageReferenceChange: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var opportunityId = myPageRef.state.c__opportunityId;
        cmp.set("v.opportunityId", opportunityId);
    }
});