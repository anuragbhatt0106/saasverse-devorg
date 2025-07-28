public class ProjectTaskTriggerHandler {
    
    
    public static void calculateEffort(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap, Boolean isDelete) {
        Set<Id> projectIds = new Set<Id>();

        // Collect project IDs from Trigger.new and Trigger.old
        if (newList != null) {
            for (Project_Task__c task : newList) {
                if (task.Projects__c != null) {
                    projectIds.add(task.Projects__c);
                }
            }
        }

        if (oldMap != null) {
            for (Project_Task__c oldTask : oldMap.values()) {
                if (oldTask.Projects__c != null) {
                    projectIds.add(oldTask.Projects__c);
                }
            }
        }

        if (projectIds.isEmpty()) return;

        // Fetch all tasks under affected projects
        List<Project_Task__c> allTasks = [
            SELECT Id, Projects__c, Is_Active__c, Current_Task_Status__c, Estimated_Effort_in_hrs__c
            FROM Project_Task__c
            WHERE Projects__c IN :projectIds
        ];

        // Group tasks by project
        Map<Id, List<Project_Task__c>> projectToTasks = new Map<Id, List<Project_Task__c>>();
        for (Project_Task__c task : allTasks) {
            if (!projectToTasks.containsKey(task.Projects__c)) {
                projectToTasks.put(task.Projects__c, new List<Project_Task__c>());
            }
            projectToTasks.get(task.Projects__c).add(task);
        }

        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();

        // Recalculate efforts for each project
        for (Id projectId : projectToTasks.keySet()) {
            List<Project_Task__c> tasks = projectToTasks.get(projectId);
            List<Project_Task__c> activeTasks = new List<Project_Task__c>();

            // Step 1: Count active & non-completed tasks
            for (Project_Task__c task : tasks) {
                if (task.Is_Active__c && task.Current_Task_Status__c != 'Task Completed') {
                    activeTasks.add(task);
                }
            }

            Integer activeCount = activeTasks.size();
            Decimal newEffort = activeCount > 0 ? (8.0 / activeCount) : 0;

            // Step 2: Assign efforts
            for (Project_Task__c task : tasks) {
                Decimal expectedEffort = (task.Is_Active__c && task.Current_Task_Status__c != 'Task Completed')
                    ? newEffort
                    : 0;

                if (task.Estimated_Effort_in_hrs__c != expectedEffort) {
                    task.Estimated_Effort_in_hrs__c = expectedEffort;
                    tasksToUpdate.add(task);
                }
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            try {
                update tasksToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Estimated Effort: ' + e.getMessage());
            }
        }
    }

    
    public static void calculateHoursSoFarConsumed(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;
    
        for (Project_Task__c task : newList) {
            try {
                // Inactive or Completed task → Set hours to 0
                if (
                    task.Is_Active__c == false ||
                    task.Current_Task_Status__c == 'Task Completed' ||
                    task.Development_Start_Date__c == null ||
                    task.Estimated_Effort_in_hrs__c == null
                ) {
                    task.Hours_so_Far_consumed__c = 0;
                    continue;
                }
    
                // Else, calculate based on working days
                Date startDate = task.Development_Start_Date__c;
                Date endDate = task.LastModifiedDate.date();
    
                Integer workingDays = 0;
                Integer totalDays = startDate.daysBetween(endDate) + 1;
    
                for (Integer i = 0; i < totalDays; i++) {
                    Date currentDate = startDate.addDays(i);
                    Integer dayOfWeek = Integer.valueOf(
                        DateTime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0)).format('u')
                    );
                    if (dayOfWeek < 6) {
                        workingDays++;
                    }
                }
    
                Decimal totalHours = workingDays * task.Estimated_Effort_in_hrs__c;
                task.Hours_so_Far_consumed__c = totalHours.setScale(2);
    
            } catch (Exception e) {
                System.debug('Error calculating consumed hours for task: ' + task.Id + ' - ' + e.getMessage());
            }
        }
	}  
    
    
    /*public static void updateIsWorkingOnOtherTickets(List<Project_Task__c> newList) {
        System.debug('newList RESULT::' + newList);
        
        Map<String,List<Project_Task__c>> mapOfProjectTask = new Map<String,List<Project_Task__c>>();
        for (Project_Task__c pt : newList) {
            if (!mapOfProjectTask.containsKey(pt.Project_Task_Name__c)) {
                mapOfProjectTask.put(pt.Project_Task_Name__c, new List<Project_Task__c>());
            }
            mapOfProjectTask.get(pt.Project_Task_Name__c).add(pt);
        }
        for(Project_Task__c pt : newList){
            List<Project_Task__c> ptList = mapOfProjectTask.get(pt.Project_Task_Name__c);
            if(ptList.size() > 1){
                if(pt.Is_Working_on_Other_Tickets__c != pt.Is_Active__c){
                pt.Is_Working_on_Other_Tickets__c = pt.Is_Active__c;
            	}
            }
        }
    }*/
    
	public static void updateIsWorkingOnOtherTickets(Set<Id> taskIds) {
        // Step 1: Get related project IDs
        Set<Id> projectIds = new Set<Id>();
        for(Project_Task__c task : [SELECT Id, Projects__c  FROM Project_Task__c WHERE Id IN :taskIds]){
            projectIds.add(task.Projects__c );
        }
 
        if(projectIds.isEmpty()) return;
 
        // Step 2: Get all tasks for these projects
        List<Project_Task__c> allTasks = [
            SELECT Id, Projects__c , Is_Active__c, Is_Working_on_Other_Tickets__c 
            FROM Project_Task__c 
            WHERE Projects__c  IN :projectIds
        ];
 
        // Step 3: Group tasks by project
        Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
        for(Project_Task__c pt : allTasks){
            if (!tasksByProject.containsKey(pt.Projects__c)) {
    		tasksByProject.put(pt.Projects__c, new List<Project_Task__c>());
				}
			tasksByProject.get(pt.Projects__c).add(pt); 
        }
 
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();
 
        // Step 4: Apply logic per project
        for(Id projId : tasksByProject.keySet()){
            List<Project_Task__c> taskList = tasksByProject.get(projId);
            List<Project_Task__c> activeTasks = new List<Project_Task__c>();
 
            for(Project_Task__c pt : taskList){
                if(pt.Is_Active__c){
                    activeTasks.add(pt);
                }
            }
 
            Boolean moreThanOneActive = activeTasks.size() > 1;
 
            for(Project_Task__c pt : taskList){
                Boolean shouldBeTrue = pt.Is_Active__c && moreThanOneActive;
                if(pt.Is_Working_on_Other_Tickets__c != shouldBeTrue){
                    pt.Is_Working_on_Other_Tickets__c = shouldBeTrue;
                    tasksToUpdate.add(pt);
                }
            }
        }
 
        if(!tasksToUpdate.isEmpty()){
            update tasksToUpdate;
        }
    }
    
    
   /* public static void updateProjectTaskScore(Set<Id> taskIds) {
    // Step 1: Get related Project IDs
        Set<Id> projectIds = new Set<Id>();
        for (Project_Task__c task : [SELECT Id, Projects__c FROM Project_Task__c WHERE Id IN :taskIds]) {
            if (task.Projects__c != null) {
                projectIds.add(task.Projects__c);
            }
        }
        if (projectIds.isEmpty()) return;
    
        // Step 2: Query all ACTIVE tasks with RAG for these projects
        List<Project_Task__c> allTasks = [
            SELECT Id, Projects__c, RAG__c, Is_Active__c,Real_Business_hours_needed__c 
            FROM Project_Task__c
            WHERE Projects__c IN :projectIds AND Is_Active__c = true AND Real_Business_hours_needed__c  != NULL
        ];
    
        // Step 3: Group tasks by project
        Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
        for (Project_Task__c task : allTasks) {
            if (!tasksByProject.containsKey(task.Projects__c)) {
                tasksByProject.put(task.Projects__c, new List<Project_Task__c>());
            }
            tasksByProject.get(task.Projects__c).add(task);
        }
    
        // Step 4: Calculate average score and update Projects
        List<Project__c> projectsToUpdate = new List<Project__c>();
    
        for (Id projectId : tasksByProject.keySet()) {
            List<Project_Task__c> taskList = tasksByProject.get(projectId);
    
            Integer totalScore = 0;
            Integer totalActiveTasks = taskList.size();
    
            for (Project_Task__c task : taskList) {
                if (task.RAG__c == '🟢 Green') {
                    totalScore += 1;
                } else if (task.RAG__c == '🟠 Orange') {
                    totalScore += 2;
                } else if (task.RAG__c == '🔴 Red') {
                    totalScore += 3;
                }
            }
    
            Decimal averageScore = totalActiveTasks > 0 ? Decimal.valueOf(totalScore) / totalActiveTasks : 0;
    
            projectsToUpdate.add(new Project__c(
                Id = projectId,
                Task_Score__c = averageScore.setScale(2)
            ));
        }
    
        if (!projectsToUpdate.isEmpty()) {
            update projectsToUpdate;
        }
	}*/
	
    
    public static void updateProjectTaskScore(Set<Id> taskIds) {
    // Step 1: Get related Project IDs
    Set<Id> projectIds = new Set<Id>();
    for (Project_Task__c task : [
        SELECT Id, Projects__c 
        FROM Project_Task__c 
        WHERE Id IN :taskIds
    ]) {
        if (task.Projects__c != null) {
            projectIds.add(task.Projects__c);
        }
    }
    if (projectIds.isEmpty()) return;

    // Step 2: Query all ACTIVE tasks for those projects
    List<Project_Task__c> allTasks = [
        SELECT Id, Projects__c, RAG__c, Is_Active__c, Real_Business_hours_needed__c 
        FROM Project_Task__c
        WHERE Projects__c IN :projectIds
        AND Is_Active__c = true
    ];

    // Step 3: Group tasks by project
    Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
    for (Project_Task__c task : allTasks) {
        if (!tasksByProject.containsKey(task.Projects__c)) {
            tasksByProject.put(task.Projects__c, new List<Project_Task__c>());
        }
        tasksByProject.get(task.Projects__c).add(task);
    }

    // Step 4: Calculate and update Task Score on Projects
    List<Project__c> projectsToUpdate = new List<Project__c>();

    for (Id projectId : tasksByProject.keySet()) {
        List<Project_Task__c> taskList = tasksByProject.get(projectId);

        Integer totalScore = 0;
        Integer totalValidTasks = 0;

        for (Project_Task__c task : taskList) {
            // Only include tasks with non-null Real Business Hours
            if (task.Real_Business_hours_needed__c != null) {
                totalValidTasks++;

                if (task.RAG__c == '🟢 Green') {
                    totalScore += 1;
                } else if (task.RAG__c == '🟠 Orange') {
                    totalScore += 2;
                } else if (task.RAG__c == '🔴 Red') {
                    totalScore += 3;
                }
            }
        }

        Decimal avgScore = (totalValidTasks > 0) ? 
            Decimal.valueOf(totalScore) / totalValidTasks : null;

        projectsToUpdate.add(new Project__c(
            Id = projectId,
            Task_Score__c = (avgScore != null) ? avgScore.setScale(2) : null
        ));
    }

    if (!projectsToUpdate.isEmpty()) {
        update projectsToUpdate;
    }
}

    
   
}