/*
* This trigger is for any updates happening on Employee Store Retail data which manager add/remove store from an Employee
* Author:Rashmi Thippeswamy
*/
trigger EmployeeStoreRetailTrigger on EmployeeStoreRetail__c (before insert,before update,after insert,after update){
    new EmployeeStoreRetailTriggerHandler().run();
}