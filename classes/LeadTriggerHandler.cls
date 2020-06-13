/*
* This class contains the business logic for various actions performed on various lead trigger events
*/
public with sharing class LeadTriggerHandler {
    /*
    * This method is called on BeforeInsert Lead trigger event
    */
    public void OnBeforeInsert(Map<Id, Lead> newLeadsMap) {
    } 
    /*
    * This method is called on AfterInsert Lead trigger event
    */
    public void OnAfterInsert(Map<Id, Lead> newLeadsMap) {
        LeadSharingHandler.processLeadSharing(newLeadsMap, null);
    } 
    
    /*
    * This method is called on BeforeUpdate Lead trigger event
    */
    public void OnBeforeUpdate(Map<Id, Lead> oldLeadsMap, Map<Id, Lead> newLeadsMap) {
    }
    /*
    * This method is called on AfterUpdate Lead trigger event
    */
    public void OnAfterUpdate(Map<Id, Lead> oldLeadsMap, Map<Id, Lead> newLeadsMap) {
        LeadSharingHandler.processLeadSharing(newLeadsMap, oldLeadsMap);
    } 


}