public class DailyProjectTaskEmailReminder {

    public static void sendDailyProjectTaskSummaryEmail() {
        List<Project_Task__c> allTasks = [
            SELECT 
                Id,
                Name,
                Projects__c,
                Projects__r.Name,
                Assigned_To1__c,
                Assigned_To1__r.Name,
                Development_Start_Date__c,
                Hours_so_Far_consumed__c,
                LastModifiedDate,
                RAG__c,
                Current_Task_Status__c
            FROM Project_Task__c
            WHERE Assigned_To1__c != null AND Projects__c != null AND RAG__c != '🟢 Green'
            ORDER BY Assigned_To1__r.Name, Projects__r.Name
        ];

        // Group by Developer and Project
        Map<Id, Map<Id, List<Project_Task__c>>> dataMap = new Map<Id, Map<Id, List<Project_Task__c>>>();
        Map<Id, String> developerNames = new Map<Id, String>();
        Map<Id, String> projectNames = new Map<Id, String>();

        for (Project_Task__c task : allTasks) {
            Id devId = task.Assigned_To1__c;
            Id projId = task.Projects__c;

            if (!dataMap.containsKey(devId)) {
                dataMap.put(devId, new Map<Id, List<Project_Task__c>>());
                developerNames.put(devId, task.Assigned_To1__r.Name);
            }
            if (!dataMap.get(devId).containsKey(projId)) {
                dataMap.get(devId).put(projId, new List<Project_Task__c>());
                projectNames.put(projId, task.Projects__r.Name);
            }

            dataMap.get(devId).get(projId).add(task);
        }

        String body = '<html><body style="font-family: Arial;">';
        body += '<p>Hello,</p>';
        body += '<p>This is a testing email.</p>';
        body += '<p>Here is the daily summary of developer project tasks:</p>';

        body += '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead style="background-color: #f2f2f2;">';
        body += '<tr>';
        body += '<th>Developer Name</th>';
        body += '<th>Project Name</th>';
        body += '<th>Task Name</th>';
        body += '<th>Dev Start Date</th>';
        body += '<th>Hours Consumed</th>';
        body += '<th>Last Modified</th>';
        body += '<th>Current Status</th>';  
        body += '<th>RAG</th>';
        body += '</tr>';
        body += '</thead><tbody>';

        for (Id devId : dataMap.keySet()) {
            Map<Id, List<Project_Task__c>> projects = dataMap.get(devId);
            Integer devRowspan = 0;

            for (List<Project_Task__c> taskList : projects.values()) {
                devRowspan += taskList.size();
            }

            Boolean firstDevRow = true;
            for (Id projId : projects.keySet()) {
                List<Project_Task__c> taskList = projects.get(projId);
                Boolean firstProjRow = true;

                for (Project_Task__c task : taskList) {
                    body += '<tr>';
                    if (firstDevRow) {
                        body += '<td rowspan="' + devRowspan + '">' + escapeHtml(developerNames.get(devId)) + '</td>';
                        firstDevRow = false;
                    }
                    if (firstProjRow) {
                        body += '<td rowspan="' + taskList.size() + '">' + escapeHtml(projectNames.get(projId)) + '</td>';
                        firstProjRow = false;
                    }

                    body += '<td>' + escapeHtml(task.Name) + '</td>';
                    body += '<td>' + formatDate(task.Development_Start_Date__c) + '</td>';
                    body += '<td>' + (task.Hours_so_Far_consumed__c != null ? String.valueOf(task.Hours_so_Far_consumed__c) : '-') + '</td>';
                    body += '<td>' + formatDateTime(task.LastModifiedDate) + '</td>';
                    body += '<td>' + escapeHtml(task.Current_Task_Status__c) + '</td>';  
                    body += '<td>' + escapeHtml(task.RAG__c) + '</td>';
                    body += '</tr>';
                }
            }
        }

        body += '</tbody></table>';
        body += '<p>Regards,<br/>Internal Project Admin</p>';
        body += '</body></html>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{  }); // Replace as needed
        mail.setSubject('Project Health Update - ' + DateTime.now().format('MMMM d, yyyy'));
        mail.setHtmlBody(body);
        mail.setSenderDisplayName('Internal Project Admin');

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private static String formatDate(Date d) {
        return d != null ? d.format() : '-';
    }

    private static String formatDateTime(Datetime dt) {
        return dt != null ? dt.format('MMM d, yyyy hh:mm a') : '-';
    }

    private static String escapeHtml(String input) {
        if (String.isBlank(input)) return '';
        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }
}