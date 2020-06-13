/*
* This trigger is for any updates happening on Employee data feed. Specially on home store location changes
*  Delegation to Apex classes to perform actual execution of the logic
*/
trigger EmployeeTrigger on Employee__c (before insert,before update,after insert,after update) {        
   new EmployeeTriggerHandler().run();
}