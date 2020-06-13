/*
* This class is called from the Employee Trigger to handle various scenarios to be covered for all events on Employee Object
* Currently, this class handles Employee offboarding, Home store change, position change
* Author: Mohit Pandey
*/
public with sharing class EmployeeTriggerHandler extends TriggerHandler {

    public override void afterUpdate(){
        processEmployeeUpdates(Trigger.oldMap, Trigger.newMap);
        //Promotion or Demotion
        Map<Id,Employee__c> mapEmp = new Map<Id,Employee__c>();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        Store st = new PromotionDemotion();
        TriggerHelper.RoleMap roleMap = new TriggerHelper.RoleMap();
        List<EmployeeStoreRetail__c> lstEmpStoreRetail = new  List<EmployeeStoreRetail__c>();
        //check if the employee's profile is updated to promote or demote
        mapEmp = EmployeeTriggerHelper.checkIfProfileIsChanged(( Map<Id,Employee__c>)Trigger.NewMap,( Map<Id,Employee__c>)Trigger.OldMap);
        if(!mapEmp.isEmpty()){
            //Get all  the employee store association records to determine whether to provision or remove access to the store's leads
            lstEmpStoreRetail = [SELECT id, Employee__c,Store__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c WHERE Employee__c IN: mapEmp.keySet()];
            if(!lstEmpStoreRetail.isEmpty()){
                //Get employees grouped by roles and stores 
                roleMap = TriggerHelper.getEmployeeRoleMapping(lstEmpStoreRetail,Trigger.Old,Trigger.NewMap,Trigger.OldMap);
               //Provision access to leads based on the following conditions
               //Case 1:Rep to SM-Promotion-add lead share Read/Write
               //Case2:SM to ARSM - Promotion-add lead share Read Only
                lstLeadShare = st.addLeadShare(roleMap);
                //Case3:ARSM to SM-Demotion-update lead share from Read Only to Read/write
               //Case4:SM to REP - remove lead share except for owned leads
                lstLeadShare = st.removeLeadShare(roleMap);
            }
        }
    }

    /* 
    *This method is called on Employee object update and performs updates to Lead object if Store or Profile Changes
    */
    public static void processEmployeeUpdates(Map<Id, sObject> oldsObjMap, Map<Id, sObject> newsObjMap) {
        map<Id, Employee__c> oldEmpMap = (map<Id, Employee__c>) oldsObjMap;
        map<Id, Employee__c> newEmpMap = (map<Id, Employee__c>) newsObjMap;
        
        set<Id> storeIdSet = new set<Id>(); //set to store all the store ids (old, new store) to fetch them form database 
        map<Id,Store__c> storeMap = new map<Id,Store__c>(); //map to store all the stores required for current transaction
        
        map<Id, map<Id, Id>> userToOldToNewStoreMap = new map<Id, map<Id, Id>>(); //user id, to old store id, to new store id map; 
        //userToOldToNewStoreMap is populated only for the scenario where the Store of the Lead needs to be updated
        set<Id> updateStoreIdSet = new set<Id>(); //set of store ids for which the leads store need to be updated
        set<Id> redistributeLeadUserIdSet = new set<Id>(); //set of user ids from whom the leads need to be redistributed 
        set<Id> redistributeLeadStoreIdSet = new set<Id>(); //set of store ids from which the lead  needs to be redistributed
        set<Employee__c> homeStoreChangeEmpSet = new set<Employee__c>();  //list of employees for whom the home store has been changed
        map<Id,Id> offboardEmployeeMap = new map<Id,Id>();
        list<Lead> updateLeadList = new list<Lead>();
               
        for(Employee__c emp : newEmpMap.values()){
            Employee__c oldEmp = null;
            oldEmp = oldEmpMap.get(emp.Id);
            //Fetch Employees for whom the Home Store was changed to perform redistribution
            if(oldEmp.HomeStoreLocation__c != emp.HomeStoreLocation__c) {
                homeStoreChangeEmpSet.add(emp);             
                storeIdSet.add(oldEmp.HomeStoreLocation__c);
                storeIdSet.add(emp.HomeStoreLocation__c);
            }
            //Fetch Employees who have been offboarded to perform redistribution
            if(!emp.IsActive__c && emp.IsActive__c != oldEmp.IsActive__c) {
                offboardEmployeeMap.put(emp.Id, emp.User__c);
                //redistributeLeadUserIdSet.add(emp.User__c);
            }
        }
        
        //Fetch the stores for whom emplpoyee has changed the store
        storeMap = new map<Id, Store__c>([SELECT  Id, GeoLocation__c FROM Store__c WHERE ID IN :storeIdSet]);

        //Loop thru New/Old Employee Map and get the associated HomeStoreLocations' GeoLoc
        for(Employee__c emp : homeStoreChangeEmpSet) {
            Employee__c oldEmp = oldEmpMap.get(emp.Id);
            Double distBetStores = RedistributeLeadHandler.calculateDistance(storeMap.get(oldEmp.HomeStoreLocation__c), storeMap.get(emp.HomeStoreLocation__c)); 
            if(distBetStores != null && distBetStores <= RetailConstants.REDISTRIBUTE_THRESHOLD) {
                //If the distance between stores is less than threshhold, we populate data for updates Stores for leads owned by Employee
                updateStoreIdSet.add(oldEmp.HomeStoreLocation__c);
                userToOldToNewStoreMap = RedistributeLeadHandler.populateEmployeeToStoreChangeMap(userToOldToNewStoreMap, emp, oldEmp);
            } else {
                //If the distance between stores is greater than threhold, we popylate data for redistributing leads owned by Employee
                redistributeLeadUserIdSet.add(emp.User__c);
                redistributeLeadStoreIdSet.add(oldEmp.HomeStoreLocation__c);
            }
        }
        if(!offboardEmployeeMap.isEmpty()) {
            set<Id> offboardStoreSet = RedistributeLeadHandler.fetchStoresForEmployee(offboardEmployeeMap.keyset());
            set<Id> offboardUserSet = new set<Id>();
            offboardUserSet.addAll(offboardEmployeeMap.values());
            updateLeadList.addAll(RedistributeLeadHandler.redistributeLeads(offboardUserSet, offboardStoreSet, RetailConstants.EMPLOYEE_OFFBOARD));
        }
        //Perform actions for Leads
        if(!userToOldToNewStoreMap.isEmpty())
            updateLeadList.addAll(RedistributeLeadHandler.updateLeadStore(userToOldToNewStoreMap, updateStoreIdSet));
        if(!redistributeLeadUserIdSet.isEmpty())
            updateLeadList.addAll(RedistributeLeadHandler.redistributeLeads(redistributeLeadUserIdSet, redistributeLeadStoreIdSet, RetailConstants.HOME_STORE_CHANGE));
        if(!updateLeadList.isEmpty())
            update updateLeadList;
    }
    
}