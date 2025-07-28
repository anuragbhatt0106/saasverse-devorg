@RestResource(urlMapping='/syncAccount/*')
global with sharing class AccountSyncService {
    @HttpPost
    global static String createOrUpdateAccount(String accountName, String division, String industry, String phone) {
        try {
            // Check if Division is "Printing.com" and create a new record
            if (division == 'Printing.com') {
                Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Printing_com' AND SObjectType = 'Account' LIMIT 1].Id;
                Account newAcc = new Account(
                    Name = accountName,
                    Industry = industry,
                    Phone = phone,
                    RecordTypeId = recordTypeId
                );
                insert newAcc;
                return 'New Account created with Printing.com record type: ' + newAcc.Id;
            }

            // If Division is not "Printing.com", update existing records
            Account acc = [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
            acc.Industry = industry;
            acc.Phone = phone;
            update acc;
            return 'Account updated successfully: ' + acc.Id;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}