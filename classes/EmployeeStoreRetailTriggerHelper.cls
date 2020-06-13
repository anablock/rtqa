/*
* This class is called from the Employee Store Retail  Trigger and subsequently from Trigger helper 
*to handle various scenarios to be covered for all events on EmployeeStore Retail  Object's insert / update
* Currently, this class handles checking conditions for add/remove store and redistribution of leads when a rep is removed from a store
* Author: Rashmi Thippeswamy
*/
public class EmployeeStoreRetailTriggerHelper {
     /* 
    *This method is called on Employee Store Retail object's insert/update to check the conditions for add/remove store 
    */
    public static TriggerHelper.RoleMap checkEmployeeStoreRetailConditions(TriggerHelper.RoleMap roleMap,EmployeeStoreRetail__c empStoreRec ,Map<Id,Set<Id>> mapStoreVSuserId,Map<Id,EmployeeStoreRetail__c> mapEmpStoreNew,Map<Id,EmployeeStoreRetail__c> mapEmpStoreOld){
        if(mapEmpStoreOld != NULL && !mapEmpStoreOld.isEmpty()){
            //if isExpired__c is checked then remove employee from store
            if(mapEmpStoreNew.get(empStoreRec.Id).IsExpired__c == true && mapEmpStoreOld.get(empStoreRec.Id).IsExpired__c == false){
                roleMap.mapRoleVSmapStoreUsrRem = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrRem,mapStoreVSuserId,empStoreRec);
            }
             //if isExpired__c is unchecked then add employee to a store
            else if(mapEmpStoreNew.get(empStoreRec.Id).IsExpired__c == false && mapEmpStoreOld.get(empStoreRec.Id).IsExpired__c == true){
                roleMap.mapRoleVSmapStoreUsrAdd = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
            }
        }
        //if isExpired__c is unchecked during insert then add employee from store
        else{
            roleMap.mapRoleVSmapStoreUsrAdd = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
        }
      return roleMap;
    }
 /* 
    *This method is called on Employee Store Retail object's update to check if a rep who is removed from store
    *owns leads. Those leads gets redistributed within the store
*/
    public static List<Lead> redistributeLeads(List<LeadShare> lstleadShare){
        Map<Id,Set<Id>> mapStoreVSuserId = new Map<Id,Set<Id>>();
        Set<Id> setUserIds = new Set<Id>();
        Set<Id> setStoreIds = new Set<Id>();
        for(LeadShare ls : lstleadShare){
            //extract all the REPs who are owners of leads
            setUserIds.add(ls.UserOrGroupId);
            //extract all the stores belonging to those leads
            setStoreIds.add(ls.Lead.Store__c);
        }
        return RedistributeLeadHandler.redistributeLeads(setUserIds,setStoreIds, RetailConstants.EMP_REMOVE_LOCATION);
    }
}