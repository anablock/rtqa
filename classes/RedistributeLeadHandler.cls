/*
* This class contains the logic for various business process for redistributing Leads (update Lead Owner) or changing the Lead Store
* Author: Reshma Jewrani
*/
public without sharing class RedistributeLeadHandler {

    /*
    * This method is called to calculate the distance between the stores using lat/long data on the Store Object
    */ 
    public static Double calculateDistance(Store__c oldStore, Store__c newStore) { 
        if(oldStore != null && oldStore.GeoLocation__c != null && newStore.GeoLocation__c != null) { 
            Location oldGeoLoc = oldStore.GeoLocation__c;
            Location newGeoLoc = newStore.GeoLocation__c;
            Double dist = oldGeoLoc.getDistance(newGeoLoc, 'mi');
            system.debug('Distance is......' + dist);            
            return dist;
        }
        //As per Roy, if lat long doesn't exist, redistribute the leads. 
        //Returning null here would pass this employee data for Lead redistribution
        return null;
    }

    /*
    * This method is called to update the store for all Leads owned by Employee
    * This scenariooccurs when an Employee is changing Home Store locationa and the distance between old and new store is less than the threshold
    */
    public static List<Lead> updateLeadStore(map<Id, map<Id, Id>> userToOldToNewStoreMap, set<id> updateStoreIdSet) {
        List<Lead> updateLeadList = new List<Lead>(); //list of leads to be updated
        //fetch the Leads to update the owner
        List<Lead> leadList = [SELECT Id,Store__c, OwnerId FROM Lead WHERE OwnerId IN:userToOldToNewStoreMap.keySet() AND Store__c IN :updateStoreIdSet AND Status != :RetailConstants.CLOSED];

        for(Lead leadRec : leadList) {
            if(userToOldToNewStoreMap.containsKey(leadRec.OwnerId)) {
                system.debug('lead Owner id....' + leadRec.OwnerId + '...for Lead...' + leadRec.Id + '..Old Store...'+ leadRec.Store__c+'..New Store...'+userToOldToNewStoreMap.get(leadRec.OwnerId).get(leadRec.Store__c));
                //Update the Store for the lead record maintaining the owner
                leadRec.Store__c = userToOldToNewStoreMap.get(leadRec.OwnerId).get(leadRec.Store__c);
                updateLeadList.add(leadRec);
            }
        }
        return updateLeadList;        
    }

    /*
    * This method populated the emplyee's user id to employees old store to employees new store map
    * This map is used in updateLeadStore method above
    */
    public static map<Id, map<Id, Id>>  populateEmployeeToStoreChangeMap(map<Id, map<Id, Id>> userToOldToNewStoreMap, Employee__c emp, Employee__c oldEmp) {
        map<Id ,Id> oldToNewStoreMap = new map<Id, Id>();
        if(userToOldToNewStoreMap.containsKey(emp.user__c))
            oldToNewStoreMap = userToOldToNewStoreMap.get(emp.user__c);
        oldToNewStoreMap.put(oldEmp.HomeStoreLocation__c, emp.HomeStoreLocation__c);
        userToOldToNewStoreMap.put(emp.user__c, oldToNewStoreMap);
        return userToOldToNewStoreMap;
    }

    /*
    * This method is called to distribute the Leads owned by user in redistributeLeadStoreIdSet for store redistributeLeadSet
    * This scenario occurs when 
    *   An Employee is changing Home Store locationa and the distance between old and new store is less than the threshold
    *   An Employee has been  removed from a Store/Location
    *   An Employee is offboarded
    */
    public static list<Lead> redistributeLeads(set<Id> userIdSet, set<Id> storeIdSet) {
        list<Lead> updateLeadList = new List<Lead>(); //list of leads to be updated
        //Fetch the various reps for the Store between whom the leads need to be redistributed
        map<Id, list<Id>> storeToUserMap = fetchStoreToEmployeeMap(storeIdSet);
        map<Id, Integer> storeToIndexMap = new map<Id, Integer>(); //map to maintain the index for Owner assignment for the Leads

        //Fetch the Leads to be redistributed
        List<Lead> leadList = [SELECT Id,Store__c, OwnerId FROM Lead WHERE OwnerId IN :userIdSet AND Store__c IN :storeIdSet AND Status != :RetailConstants.CLOSED];
        for(Lead leadRec: leadList) {
            if(userIdSet.contains(leadRec.ownerId) && storeIdSet.contains(leadRec.Store__c)) {
                updateLeadList.add(updateleadOwner(leadRec, storeToUserMap, storeToIndexMap));
            }
        }
        return updateLeadList;
    }

    public static list<Lead> redistributeLeads(set<Id> userIdSet, set<Id> storeIdSet, String reassignmentReason) {
        list<Lead> updateLeadList = new List<Lead>(); //list of leads to be updated
        //Fetch the various reps for the Store between whom the leads need to be redistributed
        map<Id, list<Id>> storeToUserMap = fetchStoreToEmployeeMap(storeIdSet);
        map<Id, Integer> storeToIndexMap = new map<Id, Integer>(); //map to maintain the index for Owner assignment for the Leads

        //Fetch the Leads to be redistributed
        List<Lead> leadList = [SELECT Id,Store__c, OwnerId FROM Lead WHERE OwnerId IN :userIdSet AND Store__c IN :storeIdSet AND Status != :RetailConstants.CLOSED];
        for(Lead leadRec: leadList) {
            if(userIdSet.contains(leadRec.ownerId) && storeIdSet.contains(leadRec.Store__c)) {
                leadRec.ReassignmentReason__c = reassignmentReason;
                leadRec = updateleadOwner(leadRec, storeToUserMap, storeToIndexMap);
                updateLeadList.add(leadRec);
            }
        }
        return updateLeadList;
    }
    /*
    * This method updates the appropriate owner field for the Lead to redistribute the LEads evenly
    */
    private static Lead updateleadOwner(Lead leadRecord, map<Id, list<Id>> storeToUserMap, map<Id, Integer> storeToIndexMap) {
        Integer index = 0;
        if(storeToIndexMap.containsKey(leadRecord.Store__c)) {
            index = storeToIndexMap.get(leadRecord.Store__c); //fetch the index to assign the Lead owner
        }
        //If size == 0, there are no other Reps to redistribute Lead to, hence nothing happens. Check what should be done in this scenarios
        if(storeToUserMap.containsKey(leadRecord.Store__c) && storeToUserMap.get(leadRecord.Store__c).size() > 0) {
            if(storeToUserMap.get(leadRecord.Store__c).get(index) == leadRecord.OwnerId) { 
                //If new employee is same as previous owner of LEad, fetch next employee
                index = updateRedistributeIndex(storeToUserMap.get(leadRecord.Store__c), index);
            }
            //Update Lead Owner
            leadRecord.OwnerId = storeToUserMap.get(leadRecord.Store__c).get(index);
            
            //update the index to allow fetcging next employee for next lead
            index = updateRedistributeIndex(storeToUserMap.get(leadRecord.Store__c), index);
            storeToIndexMap.put(leadRecord.Store__c, index);
        } else {
            leadRecord.ReassignmentReason__c = 'No other active Reps for Store. Hence, cannot redistribute';
        }
        return leadRecord;
    }

    /*
    * This method updates the index field to allow the redistribute the Leads evenly
    */
    private static Integer updateRedistributeIndex(list<Id> employeeList, Integer index) {
        index++;
        if(index >= employeeList.size()) {
            index = 0;
        }
        return index;
    }

    /*
    * This method fetches the various employee (Only Reps) for the stores passed to allow the redistribution of Leads 
    */
    public static map<Id, list<Id>>  fetchStoreToEmployeeMap(set<Id> storeIdSet) {
        list<Employee__c> empList = [SELECT id, User__c, HomeStoreLocation__c FROM Employee__c WHERE 
                                        HomeStoreLocation__c IN :storeIdSet AND 
                                        SFProfileId__c = :RetailConstants.REP_POSITION 
                                        Order By Name]; //Move the order by to custom label
        map<Id, list<Id>> storeToUserMap = new map<Id, list<Id>> (); //map of store id to list of employees user id 
        for(Employee__c emp: empList) {
            list<Id> userList = new list<id>();
            if(storeToUserMap.containsKey(emp.HomeStoreLocation__c)) {
                userList = storeToUserMap.get(emp.HomeStoreLocation__c);
            }
            userList.add(emp.User__c);
            storeToUserMap.put(emp.HomeStoreLocation__c, userList);
        }
        return storeToUserMap;
    }

    /*
    * This method fetches the various stores an employee is linked to 
    */
    public static set<Id> fetchStoresForEmployee(set<Id> employeeSet) {
        list<EmployeeStoreRetail__c> empStoreAssocList = [SELECT Store__c FROM EmployeeStoreRetail__c WHERE 
                                        Employee__c IN :employeeSet AND 
                                        isExpired__c = false]; 
        set<Id> storeIdSet = new set<Id>();
        for(EmployeeStoreRetail__c empStore: empStoreAssocList) {
            storeIdSet.add(empStore.Store__c);
        }
        return storeIdSet;
    }
}