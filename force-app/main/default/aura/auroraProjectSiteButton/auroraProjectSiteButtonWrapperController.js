({
    init: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var siteId = myPageRef.state.c__siteId;
        cmp.set("v.siteId", siteId);
    },

    onPageReferenceChange: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var siteId = myPageRef.state.c__siteId;
        cmp.set("v.siteId", siteId);
    }
});