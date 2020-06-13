/*
* This class contains all the business logic for sharing a Lead with various personas
*/
public with sharing class LeadSharingHandler {
    /*
    * This method is called from the Lead after insert and update and manages programmtic sharing od the record
    * Params
    * leadsMap -> Trigger.newMap()
    * oldMap -> Trigger.oldMap() -> null for insert
    */
    public static void processLeadSharing(Map<Id,Lead> leadsMap, map<Id, Lead> oldMap) {
        set<Id> storeIdSet = new set<Id>();
        map<Id,list<Id>> storeToLeadMap = new map<Id,list<Id>>();
        map<Id,list<Id>> oldstoreToLeadMap = new map<Id,list<Id>>();
        set<Id> oldUserIdSet = new set<Id>();
        list<LeadShare> leadShareList = new list<LeadShare>();
        for(Lead leadRec: leadsMap.values()) {
            Lead oldLead = null;
            //In Case of update check if the store has been changed and then only process the sharing
            if(oldMap != null) {
                oldLead = oldMap.get(leadRec.Id);
                /*Whenever the owner of the record is changed, the records shared via Manual Sharing are deleted
                * For standard objects, we cannot defined a rowcause. 
                * Hence, on owner change, the records shared via programmatic sharing are also lost. 
                * This scenario will reshared the records on Owner change
                */
                if(oldLead != null && oldLead.ownerId != leadRec.ownerId) {
                    storeIdSet.add(leadRec.store__c);
                    storeToLeadMap = populateStoreToLeadMap(storeToLeadMap, leadRec);
                }
                if(oldLead != null && oldLead.store__c != leadRec.store__c) {
                    storeIdSet.add(leadRec.store__c);
                    storeIdSet.add(oldLead.store__c);
                    storeToLeadMap = populateStoreToLeadMap(storeToLeadMap, leadRec);
                    oldstoreToLeadMap = populateStoreToLeadMap(oldstoreToLeadMap, oldLead);
                }
            } 
            //For insert, process the sharing, only if the store for the Lead is populated
            else if(leadRec.store__c != null) {
                storeIdSet.add(leadRec.store__c);
                storeToLeadMap = populateStoreToLeadMap(storeToLeadMap, leadRec);
            }
        }
        //Fetch relevant users for sharing from the Employee Store Association 
        List<EmployeeStoreRetail__c> employeeStoreList = [Select Employee__c, Employee__r.User__c, Store__c, Employee__r.SFProfileId__c FROM EmployeeStoreRetail__c WHERE Store__c IN :storeIdSet AND Employee__r.SFProfileId__c IN :RetailConstants.SHARE_POSITIONS];

        for(EmployeeStoreRetail__c empStoreRec: employeeStoreList) {
            //This will be used to process deletion of existing LeadShare records when the store is changed
            if(oldstoreToLeadMap.containsKey(empStoreRec.Store__c)) {
                oldUserIdSet.add(empStoreRec.Employee__r.User__c);
            }
            if(storeToLeadMap.containsKey(empStoreRec.Store__c)) {
                for(Id leadId :  storeToLeadMap.get(empStoreRec.Store__c)) {
                    String accessLevel = RetailConstants.LEAD_ACCESS_READ;
                    if(empStoreRec.Employee__r.SFProfileId__c.equalsIgnoreCase(RetailConstants.SM_POSITION))
                        accessLevel = RetailConstants.LEAD_ACCESS_ALL;
                    leadShareList.add(createLeadShare(accessLevel, leadId, empStoreRec.Employee__r.User__c));
                }
            }
        }

        //If the Store for the Lead has been changed, delete the existing LeadShare records 
        list<LeadShare> deleteLeadShareList = [Select id FROM LeadShare WHERE LeadId IN :leadsMap.keySet() AND UserOrGroupId IN :oldUserIdSet];
        if(deleteLeadShareList.size() > 0) {
            Database.DeleteResult[] deleteSaveResult = Database.delete(deleteLeadShareList, false);
        }
        Database.SaveResult[] insertSaveResult = Database.insert(leadShareList, false);
    }

    /*
    * This method populates the Store Id to List of Lead Id map
    */
    private static map<Id, list<id>> populateStoreToLeadMap(map<Id, list<id>> storeToLeadMap, Lead leadRec) {
        list<Id> leadIdList = new list<Id>();
        if(storeToLeadMap.containsKey(leadRec.store__c)) {
            leadIdList = storeToLeadMap.get(leadRec.store__c);
        }
        leadIdList.add(leadRec.Id);
        storeToLeadMap.put(leadRec.store__c, leadIdList);
        return storeToLeadMap;
    }

    /*
    * This method creats the LeadShare record based on the parameters
    * accessLevel -> Access Level for the record, Read/Edit
    * leadId -> Id of the Lead for record shring
    * userId  -> Id of the user or group for record sharing
    */
    private static LeadShare createLeadShare(String accessLevel, Id leadId, Id userId) {
        LeadShare leadShareRec = new LeadShare(
                                                LeadAccessLevel = accessLevel, 
                                                LeadId = leadId,
                                                RowCause = Schema.LeadShare.RowCause.Manual,
                                                UserOrGroupId = userId);
        return leadShareRec;
    }
}