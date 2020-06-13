/*
* This class implements Store interface to define methods for addleadshare and removeleadshare on account of an 
*Employee's promotion/Demotion .It is called from the EmployeeTriggerHandler on update context of EmployeeTrigger
* Currently, this class manages lead sharing when an employee is promoted/demoted
* Author: Rashmi Thippeswamy
*/
public class PromotionDemotion implements Store {
    /* 
    *This method is called on Employee object's SFProfileId field update to insert/update lead shares when promoted 
    *from REP to SM and SM to ARSM respectively
    */
    public List<LeadShare> addLeadShare(Object roleMap){
        return TriggerHelper.addLeadShare(roleMap);
    }
     /* 
    *This method is called on Employee object's SFProfileId field update to update/delete lead shares when demoted
    *from ARSM to SM and SM to REP respectively
    */
    public List<LeadShare> removeLeadShare(Object roleMap){
        TriggerHelper.RoleMap roleMapObj = new TriggerHelper.RoleMap();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        Map<String,List<LeadShare>> mapRoleVSleadShare = new Map<String,List<LeadShare>>();
        roleMapObj = (TriggerHelper.RoleMap)roleMap;
        if(roleMapObj.mapRoleVSmapStoreUsrRem!=NULL && ! roleMapObj.mapRoleVSmapStoreUsrRem.isEmpty()){
            //Get Lead share records by Role 
            mapRoleVSleadShare = TriggerHelper.getRoleVSleadShareMapping(roleMapObj.mapRoleVSmapStoreUsrRem);
            if(!mapRoleVSleadShare.isEmpty()){
                //Delete lead share if Current Role is REP-demoted from SM
                if(mapRoleVSleadShare.containsKey(RetailConstants.REP_POSITION) &&  !mapRoleVSleadShare.get(RetailConstants.REP_POSITION).isEmpty()){
                    lstLeadShare.addAll(TriggerHelper.dmlLeadShare(TriggerHelper.deDuplicateListLeadShare(mapRoleVSleadShare.get(RetailConstants.REP_POSITION)),RetailConstants.DELETE_OPERATION));
                }
                //Update lead share if Current Role is SM-demoted from ARSM
                if(mapRoleVSleadShare.containsKey(RetailConstants.SM_POSITION) &&  !mapRoleVSleadShare.get(RetailConstants.SM_POSITION).isEmpty()){
                    lstLeadShare.addAll(TriggerHelper.dmlLeadShare(TriggerHelper.deDuplicateListLeadShare(mapRoleVSleadShare.get(RetailConstants.SM_POSITION)),RetailConstants.UPDATE_OPERATION));
                }
            }
        }
        return lstLeadShare;
    }
}