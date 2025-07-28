public with sharing class projectTaskHandler extends TriggerHandler {
    Private List<Project_Task__c> newTaskList;
    Private Map<Id, Project_Task__c> newTaskMap;
    Private Map<Id, Project_Task__c> oldTaskMap;
    
    Public projectTaskHandler(){
        this.newTaskList = (List<Project_Task__c>)trigger.new;
        this.newTaskMap = (Map<Id, Project_Task__c>)trigger.newMap;
        this.oldTaskMap = (Map<Id, Project_Task__c>)trigger.oldMap;
    }
    
    
   /* Public override void afterInsert(){
        calculateEffort();
    } */
    Public override void afterUpdate(){
        calculateEffort();
    }
   /* Public override void afterDelete(){
        calculateEffort();
    }
    Public override void afterUndelete(){
        calculateEffort();
    }
    */
    private void calculateEffort(){
        Set<Id> projectIds = new Set<Id>();
        for(Project_Task__c task : newTaskList){
            system.debug('task==:'+task);
            if(task.Projects__c != null){
                system.debug('inside if 31');
                projectIds.add(task.Projects__c);
            }
        }
        system.debug('projectIds ==:'+projectIds);
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();
        
        Decimal calculatedEffectiveHours = 0;
        Integer taskCount;
        
        for(AggregateResult aggregate :[Select Count(Id) totalTasks from Project_Task__c where Projects__c IN : projectIds AND Is_Active__c = true]){
            taskCount = (Integer)aggregate.get('totalTasks');
        }
        system.debug('taskCount ==:'+taskCount);
        if (taskCount != null) {
            calculatedEffectiveHours = 8/taskCount;
            system.debug('calculatedEffectiveHours ==:'+calculatedEffectiveHours);
        } else {
            taskCount = 0;
        }
        
        for(Project_Task__c task : [Select Id, Estimated_Effort_in_hrs__c from Project_Task__c where Projects__c IN : projectIds AND Is_Active__c = true]){
            Project_Task__c ts = new Project_Task__c();
            ts.Id = task.Id;
            task.Estimated_Effort_in_hrs__c = calculatedEffectiveHours;
            system.debug('ts ==:'+ts);
            tasksToUpdate.add(ts);
        }
        
        if(!tasksToUpdate.isEmpty()){
            try {
                system.debug('tasksToUpdate ==:'+tasksToUpdate);
                Database.SaveResult[] srList = Database.update(tasksToUpdate, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        System.debug('Update failed: ' + sr.getErrors()[0].getMessage());
                    }
                }
            } catch (Exception ex) {
                System.debug('Update failed: ');
            }           
        }
    }
}