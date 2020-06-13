/*
* This trigger will not contain any business logic but would simply call the LeadTriggerHandler based on the event being fired
* All the business logic will reside in the respective apex class
*/
trigger LeadTrigger on Lead (after insert, after update) {
    LeadTriggerHandler handler = new LeadTriggerHandler();
    if(Trigger.isInsert && Trigger.isBefore) {
        
    }
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.newMap);
    }

    if(Trigger.isUpdate && Trigger.isBefore) {

    }
    if(Trigger.isUpdate && Trigger.isAfter) {
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    
}