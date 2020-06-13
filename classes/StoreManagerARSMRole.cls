/*
* This class implements Store interface to define methods for addleadshare and removeleadshare on account of an 
*Employee's association to a Store .It is called from the EmployeeStoreRetailTriggerHandler on insert/update context of
* EmployeeStoreRetailTrigger
* Currently, this class manages lead sharing when an employee is added to a store or removed from a store
* Author: Rashmi Thippeswamy
*/
public class StoreManagerARSMRole implements Store{
     /* 
    *This method is called on EmployeeStoreRetail object's  record creation action to insert lead shares 
    *when an SM or ARSM is added to a store
    */
    public List<LeadShare> addLeadShare(Object roleMap){
        return TriggerHelper.addLeadShare(roleMap);
    }
     /* 
    *This method is called on EmployeeStoreRetail object's  IsExpired__c field update action to remove lead shares 
    *when an SM or ARSM is removed from  a store
    */
    public List<LeadShare> removeLeadShare(Object roleMap){
        TriggerHelper.RoleMap roleMapObj = new TriggerHelper.RoleMap();
        Set<LeadShare> setLeadShare = new Set<LeadShare>();
        List<Lead> lstLeadDistribute = new List<Lead>();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        Map<String,List<LeadShare>> mapRoleVSleadShare = new Map<String,List<LeadShare>>();
        roleMapObj = (TriggerHelper.RoleMap)roleMap;
        if(roleMapObj <> NULL && roleMapObj.mapRoleVSmapStoreUsrRem!=NULL && ! roleMapObj.mapRoleVSmapStoreUsrRem.isEmpty()){
            //Get Lead share records by Role 
            mapRoleVSleadShare = TriggerHelper.getRoleVSleadShareMapping(roleMapObj.mapRoleVSmapStoreUsrRem);
            //Dedup LeadShare Records
            if(!mapRoleVSleadShare.isEmpty()){
                for(String sRole : mapRoleVSleadShare.keySet()){
                    if(sRole <> RetailConstants.LEAD_OWNER)
                        setLeadShare.addAll(mapRoleVSleadShare.get(sRole));
                }
                lstLeadShare.addAll(setLeadShare);
            }
            //Delete LeadShare Records if Expired__c is checked for a EmployeeStoreRetail__c record for an SM or ARSM
            if(!lstLeadShare.isEmpty()){
                lstLeadShare = TriggerHelper.dmlLeadShare(lstLeadShare,RetailConstants.DELETE_OPERATION);
                
            }
            //Redistribute leads when the employee is removed from the store and owns leads of that store
            if(mapRoleVSleadShare.containsKey(RetailConstants.LEAD_OWNER) 
               && mapRoleVSleadShare.get(RetailConstants.LEAD_OWNER)<> NULL
               && !mapRoleVSleadShare.get(RetailConstants.LEAD_OWNER).isEmpty()){
                lstLeadDistribute = EmployeeStoreRetailTriggerHelper.redistributeLeads(mapRoleVSleadShare.get(RetailConstants.LEAD_OWNER));
                //update lead owners such that the leads are equally distributed among the store reps
                if(!lstLeadDistribute.isEmpty()){
                     update lstLeadDistribute;  
                }
            }
        }
        return lstLeadShare;
    }
}