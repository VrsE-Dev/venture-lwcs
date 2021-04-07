public class AuroraParam implements Comparable {
    public String param;
    public Integer bytes;

    public AuroraParam(String param) {
        bytes = Blob.valueOf(param).size();

        System.debug('Aurora param param: ' + param);
    }
    
	// Compare opportunities based on the TSRF value.
    public Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        AuroraParam compareToAuroraParam = (AuroraParam)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (bytes > compareToAuroraParam.bytes) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (bytes < compareToAuroraParam.bytes) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }

}