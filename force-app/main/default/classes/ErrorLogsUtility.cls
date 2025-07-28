public class ErrorLogsUtility {
    public static void logError(Integer lineNumber, String errorMessage, String className, String recordId) {
        
        List<Error_Logs__c> errorLogToInsert = new List<Error_Logs__c>();
        Error_Logs__c log = new Error_Logs__c();
        log.Error_Message__c  = errorMessage;
        log.Exception_Origin__c   = className;
        log.Invoice__c = recordId;
        log.Line_Number__c = lineNumber;
        errorLogToInsert.add(log);
        try {
            Database.SaveResult[] srList = Database.insert(errorLogToInsert, false);
            for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        System.debug('Update failed: ' + sr.getErrors()[0].getMessage());
                    }
                }
        } catch (Exception ex) {
            // Optionally: handle logging failure (e.g., send email, or just swallow to avoid recursion)
        }
    }
}