public class GenericErrorLogWrapper {
    
    @AuraEnabled
    public string StatusCode;
    @AuraEnabled
    public string ErrorMessage;
    @AuraEnabled
    public string FieldApiName;
    @AuraEnabled
    public string CsvFileName;
    @AuraEnabled
    public Datetime TimeStamp;
    
}