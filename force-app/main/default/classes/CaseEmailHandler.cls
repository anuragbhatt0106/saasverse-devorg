global class CaseEmailHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        result.success = true;

        // Step 1: Extract email address and content
        String fromAddress = envelope.toAddress != null ? envelope.toAddress.toLowerCase().trim() : '';
        String content = (email.subject + ' ' + email.plainTextBody).toLowerCase();

        // Step 2: Load Keyword Metadata
        Map<String, Set<String>> keywordMap = new Map<String, Set<String>>();
        Map<String, String> emailToQueueMap = new Map<String, String>();

        for (KeywordConfig__mdt config : [
            SELECT Support_Email_Address__c, Keywords__c, Routing_Queue_Name__c
            FROM KeywordConfig__mdt
            WHERE Support_Email_Address__c != null AND Keywords__c != null
        ]) {
            String key = config.Support_Email_Address__c.toLowerCase().trim();

            if (!keywordMap.containsKey(key)) {
                keywordMap.put(key, new Set<String>());
            }
            keywordMap.get(key).add(config.Keywords__c.toLowerCase());

            emailToQueueMap.put(key, config.Routing_Queue_Name__c);
        }

        // Step 3: Check for matching keyword
        Set<String> configuredKeywords = keywordMap.get(fromAddress);
        Boolean keywordMatched = false;

        if (configuredKeywords != null) {
            for (String kw : configuredKeywords) {
                if (content.contains(kw)) {
                    keywordMatched = true;
                    break;
                }
            }
        }

        if (!keywordMatched) {
            result.message = 'No matching keyword found. Case not created.';
            System.debug('result.message---->'+result.message);
            return result;
        }

        // Step 4: Extract required field values (stub logic)
        //String orderNumber = extractValue(content, 'order');
        //String issueType = extractValue(content, 'issue');
        //String productId = null; // Removed dynamic lookup for now

        // Step 5: Identify missing fields
        List<String> missingFields = new List<String>();
        //if (String.isBlank(productId)) missingFields.add('Product__c');
        //if (String.isBlank(orderNumber)) missingFields.add('Order_Number__c');
        //if (String.isBlank(issueType)) missingFields.add('Issue_Type__c');

        // Step 6: Set Case Owner (Queue)
        Id ownerId;
        if (!missingFields.isEmpty()) {
            ownerId = [SELECT Id FROM Group WHERE Name = 'General Queue' LIMIT 1].Id;
        } else {
            String routingQueue = emailToQueueMap.get(fromAddress);
            if (String.isNotBlank(routingQueue)) {
                Group queue = [SELECT Id FROM Group WHERE Name = :routingQueue LIMIT 1];
                ownerId = queue.Id;
            } else {
                ownerId = [SELECT Id FROM Group WHERE Name = 'General Queue' LIMIT 1].Id;
            }
        }

        // Step 7: Create Case
        Case c = new Case();
        c.Subject = email.subject;
        c.Description = email.plainTextBody;
        c.SuppliedEmail = envelope.fromAddress;
        //c.Order_Number__c = orderNumber;
        //c.Issue_Type__c = issueType;
        c.Origin = 'Email';
        c.OwnerId = ownerId;
        c.Status = 'New';
        //if (!String.isBlank(productId)) c.Product__c = productId;
        //c.Awaiting_Missing_Info__c = !missingFields.isEmpty();
        //c.Missing_Field_List__c = String.join(missingFields, ',');

        insert c;

        return result;
    }

    
}