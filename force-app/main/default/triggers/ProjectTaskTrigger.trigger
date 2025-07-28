trigger ProjectTaskTrigger on Project_Task__c (after update) {
	system.debug('trigger start==:');
   // new projectTaskHandler().run();
}