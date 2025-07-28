public class GenericErrorLogController {
    
    public static void addErrorLog(List<GenericErrorLogWrapper> gelws){
        
        if(gelws?.size() > 0){
            List<Generic_Error_Log__c > gelList = new List<Generic_Error_Log__c >();
            
            for(GenericErrorLogWrapper gelw : gelws){
                Generic_Error_Log__c gel = new Generic_Error_Log__c();
                gel.Status_Code__c = gelw.StatusCode;
                gel.Error_Message__c = gelw.ErrorMessage;
                gel.Field_API_Name__c = gelw.FieldApiName;
                gel.CSV_File_Name__c = gelw.CsvFileName;
                gel.Time_Stamp__c = gelw.TimeStamp;
                
                gelList.add(gel);
            }
            if(!gelList.isEmpty()){
                insert gelList;
            }
        }
    }

}