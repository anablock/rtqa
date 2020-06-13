/*
* This class implements all methods that are reused across all the Employee and Employee Store Retail Triggers
* Currently, this class contains reusable methods for lead sharing when 
*an employee is added to a store or removed from a store and employee is promoted/demoted
* Author: Rashmi Thippeswamy
*/public class TriggerHelper {
    public TriggerHelper() {

    }
    /* 
    *This is a wrapper class that holds lead share inserts in mapRoleVSmapStoreUsrAdd variable during store add and promotion
    * and mapRoleVSmapStoreUsrRem holds data for lead shares to be deleted/updated during store remove/demotion respectively
    */
    public class RoleMap{
        public Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrAdd;
        public Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrRem;
        public RoleMap(){
            mapRoleVSmapStoreUsrAdd = new Map<String,Map<Id,Set<Id>>>();
            mapRoleVSmapStoreUsrRem = new Map<String,Map<Id,Set<Id>>>(); 
        }
    }
    private static Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrAdd = new Map<String,Map<Id,Set<Id>>>();
    private static Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrRem = new Map<String,Map<Id,Set<Id>>>(); 
    /* 
    *This method is called on EmployeeStoreRetail and Employeeobject's  record creation/update action toget 
    *a map of employees to their stores and roles
    */
    public static TriggerHelper.RoleMap getEmployeeRoleMapping(List<SObject> lstNewSObj, List<SObject> lstOldSObj,    Map<Id,SObject> mapNewSObj,Map<Id,SObject> mapOldSObj){
        TriggerHelper.RoleMap roleMap = new TriggerHelper.RoleMap();
        Map<Id,Set<Id>> mapStoreVSuserId = new Map<Id,Set<Id>>(); 
        for(sObject s :lstNewSObj ){
             if(lstOldSObj!=NULL &&  !lstOldSObj.isEmpty() && lstOldSObj[0].getSObjectType().getDescribe().getName().equalsIgnoreCase(RetailConstants.EMPLOYEE)){
                 //for Employee trigger all the related employee retail stores are passes onto the lstNewSObj
                 //check if employee is promoted /demoted
                roleMap =EmployeeTriggerHelper.checkEmployeeConditions(roleMap,(EmployeeStoreRetail__c)s,mapStoreVSuserId,(Map<Id,Employee__c>)mapNewSObj,(Map<Id,Employee__c> )mapOldSObj);   
            }
            else if( s.getSObjectType().getDescribe().getName().equalsIgnoreCase(RetailConstants.EMPLOYEE_STORE_RETAIL)){
                //check if store is added /removed
                roleMap = EmployeeStoreRetailTriggerHelper.checkEmployeeStoreRetailConditions(roleMap,(EmployeeStoreRetail__c)s,mapStoreVSuserId,(Map<Id,EmployeeStoreRetail__c>)mapNewSObj,(Map<Id,EmployeeStoreRetail__c> )mapOldSObj);   
            } 
        }                                                        
        return roleMap;
    }
     /* 
    *This method is called from EmployeeStoreRetailTriggerHelper and EmployeeTriggerHelper
    * to create a map of Role=>Store>list of employees
    */
    public static Map<String,Map<Id,Set<Id>>> createRoleMap(Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsr,Map<Id,Set<Id>> mapStoreVSuserId,EmployeeStoreRetail__c empStoreRec){
        if(mapRoleVSmapStoreUsr.containsKey(empStoreRec.SFProfileId__c)){
            mapStoreVSuserId = mapRoleVSmapStoreUsr.get(empStoreRec.SFProfileId__c);
            if(mapStoreVSuserId.containsKey(empStoreRec.Store__c)){
                mapStoreVSuserId.get(empStoreRec.Store__c).add(empStoreRec.User__c);
            }
            else{
                mapStoreVSuserId.put(empStoreRec.Store__c,new Set<Id>{empStoreRec.User__c});
            }
            mapRoleVSmapStoreUsr.get(empStoreRec.SFProfileId__c).putAll(mapStoreVSuserId);
        }
        else{
            mapStoreVSuserId = new Map<Id,Set<Id>>();
            mapStoreVSuserId.put(empStoreRec.Store__c,new Set<Id>{empStoreRec.User__c});
            mapRoleVSmapStoreUsr.put(empStoreRec.SFProfileId__c,mapStoreVSuserId);
        }
        return mapRoleVSmapStoreUsr;
    }
     /* 
    *This method creates lead share instances for lead insert/update
    */
    public static LeadShare createLeadShareInstance(String accessLevel, Id leadId, Id userId) {
        LeadShare leadShareRec = new LeadShare(
                                                LeadAccessLevel = accessLevel, 
                                                LeadId = leadId,
                                                RowCause = Schema.LeadShare.RowCause.Manual,
                                                UserOrGroupId = userId);
        return leadShareRec;
    }
    /* 
    *This method is called during addleadshare method of store implementation to get all the leadshares to be inserted when 
    *a store is added /employee is promoted
    */
    public static List<LeadShare> getLeadShare(Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsr){
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        Map<Id,Set<Id>> mapTempStoreUsr = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapStoreVSuserId = new Map<Id,Set<Id>>();
        Map<Id,List<Lead>> mapStoreIdVSLead = new Map<Id,List<Lead>>();
        Map<String,Map<Id,Set<Id>>> mapTEMPRoleVSmapStoreUsr = new Map<String,Map<Id,Set<Id>>>();
        mapTEMPRoleVSmapStoreUsr.putAll(mapRoleVSmapStoreUsr);
        Set<Id> setStoreId = new Set<Id>();
        setStoreId = getMapStoreVSuserId(mapRoleVSmapStoreUsr,'store');
        for(Lead l : [SELECT id,Store__c,OwnerId FROM Lead WHERE Store__c IN:setStoreId]){
            if(mapStoreIdVSLead.containsKey(l.Store__c)){
                mapStoreIdVSLead.get(l.Store__c).add(l);
            }
            else{
                mapStoreIdVSLead.put(l.Store__c,new List<Lead>{l});
            }
        }
        //get store vs leads to provision access to the corresponding leads of the store
        if(!mapStoreIdVSLead.isEmpty()){
            for(String strRole : mapRoleVSmapStoreUsr.keySet() ){//get roles by storesVSemployee
                mapTempStoreUsr = mapRoleVSmapStoreUsr.get(strRole);
                for(Id storeId : mapTempStoreUsr.keySet()){//get stores vs employee
                    if(mapStoreIdVSLead.containsKey(storeId)){
                        for(Id usrId : mapTempStoreUsr.get(storeId)){//get employees related to a particular store
                            for(Lead l : mapStoreIdVSLead.get(storeId)){//get leads belonging to the same store
                                if(l.OwnerId <> usrId){//excluse lead owners who are reps
                                    if(strRole.equalsIgnoreCase(RetailConstants.SM_POSITION)){
                                        lstLeadShare.add(createLeadShareInstance(RetailConstants.LEAD_ACCESS_ALL,l.Id,usrId));
                                    }
                                    else if(strRole.equalsIgnoreCase(RetailConstants.ARSM_POSITION))  {
                                        lstLeadShare.add(createLeadShareInstance(RetailConstants.LEAD_ACCESS_READ,l.Id,usrId));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return lstLeadShare;
    }
    /* 
    *This method is called during addleadshare method of store implementation to get all the leadshares to be deleted/updated when 
    *a store is added /employee is demoted or whn a store is removed
    */
    public static Map<String,List<LeadShare>> getRoleVSleadShareMapping(Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsr){
        List<LeadShare> lstLeadShareTemp = new List<LeadShare>();
        List<LeadShare> lstLeadShareOwner = new List<LeadShare>();
        Map<Id,Set<Id>> mapTempStoreUsr = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapStoreVSuserId = new Map<Id,Set<Id>>();
        Map<Id,List<LeadShare>> mapUserVsLeadShare = new Map<Id,List<LeadShare>>();
        Map<String,List<LeadShare>> mapRoleVSleadShare = new Map<String,List<LeadShare>>();
        LeadShare leadshr = new LeadShare();
        Set<Id> setUserIds = new Set<Id>();
        Set<Id> setStoreIds = new Set<Id>();
        // extract userids and store ids from the map
        setUserIds = getMapStoreVSuserId(mapRoleVSmapStoreUsr,RetailConstants.USER_STRING);
        setStoreIds = getMapStoreVSuserId(mapRoleVSmapStoreUsr,RetailConstants.STORE_STRING);
        for(LeadShare ls : [SELECT id,LeadAccessLevel,UserOrGroupId,LeadId ,Lead.Store__c,Lead.OwnerId FROM LeadShare WHERE Lead.Store__c IN:setStoreIds AND UserOrGroupId IN:setUserIds ]){
            if(mapUserVsLeadShare.containsKey(ls.UserOrGroupId)){
                mapUserVsLeadShare.get(ls.UserOrGroupId).add(ls);
            }
            else{
                mapUserVsLeadShare.put(ls.UserOrGroupId,new List<LeadShare>{ls});
            }
        }
        for(String strRole : mapRoleVSmapStoreUsr.keySet() ){//get roles by storesVSemployee
            mapTempStoreUsr = mapRoleVSmapStoreUsr.get(strRole);
            for(Set<Id> setUserId : mapTempStoreUsr.values()){//get employees related to each store
                for(Id usrId : setUserId){
                    if(mapUserVsLeadShare.containsKey(usrId)){
                        for(LeadShare ls : mapUserVsLeadShare.get(usrId)){//get lead share records of each employee within the store
                            if(ls.Lead.OwnerId <> usrId){
                                //demotion scenario from ARSM to SM  provides Read/Write access
                                if(strRole.equalsIgnoreCase(RetailConstants.SM_POSITION) && usrId == ls.UserOrGroupId)  {
                                    ls.LeadAccessLevel = RetailConstants.LEAD_ACCESS_ALL;
                                }
                                //Add lead share records grouped by role 
                                if(mapRoleVSleadShare.containsKey(strRole)){
                                    mapRoleVSleadShare.get(strRole).add(ls);
                                }
                                else{
                                    mapRoleVSleadShare.put(strRole,new List<LeadShare>{ls});
                                }
                            }
                            else{
                                lstLeadShareOwner.add(ls);
                                mapRoleVSleadShare.put(RetailConstants.LEAD_OWNER,lstLeadShareOwner);
                            }
                        }
                    }
                }
            }   
        }
        return mapRoleVSleadShare;
    }
    /* 
    *This method is called from getLeadShare and getRoleVSleadShareMapping methods to extract the user id or store id sets
    */
    public static Set<Id> getMapStoreVSuserId(Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsr, String strQuery ){
        Set<Id> setIds = new Set<Id>();
        for(Map<Id,Set<Id>> mapStoreUsr : mapRoleVSmapStoreUsr.values() ){
            for(Id storeId : mapStoreUsr.keySet()){
                for(Id usrId : mapStoreUsr.get(storeId)){
                    if(strQuery.equalsIgnoreCase(RetailConstants.USER_STRING)){
                        setIds.add(usrId);
                    }
                    else if(strQuery.equalsIgnoreCase(RetailConstants.STORE_STRING)){
                        setIds.add(storeId);
                    }
                }
            }
        }
        return setIds;
    }
    /* 
    *This method is called from PromotionDemotion and StoreManagerARSMRole class to facilitate addlead share methods for storeadd/remove
    *and promotion/demotion
    */
    public static List<LeadShare> addLeadShare(Object roleMap){
        TriggerHelper.RoleMap roleMapObj = new TriggerHelper.RoleMap();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        roleMapObj = (TriggerHelper.RoleMap)roleMap;
        if(roleMapObj.mapRoleVSmapStoreUsrAdd!=NULL && ! roleMapObj.mapRoleVSmapStoreUsrAdd.isEmpty()){
            lstLeadShare = getLeadShare(roleMapObj.mapRoleVSmapStoreUsrAdd);
            if(!lstLeadShare.isEmpty()){
                lstLeadShare =dmlLeadShare(lstLeadShare,RetailConstants.INSERT_OPERATION);
            }
        }
        return lstLeadShare;
    }
    /* 
    *This method is called from PromotionDemotion  class to dedupe lead share records when grouped by store
    */
    public static List<LeadShare> deDuplicateListLeadShare(List<LeadShare> lstLeadShare){
        Set<LeadShare> setLeadShare = new Set<LeadShare>();
        List<LeadShare> lstDeDupLeadShare = new List<LeadShare>();
        for(LeadShare ls : lstLeadShare){
            setLeadShare.add(ls);
        }
        lstDeDupLeadShare.addAll(setLeadShare);
        return lstDeDupLeadShare;
    }
     /* 
    *This method is a common method to perform dml on Lead Share object
    */
    public static List<LeadShare> dmlLeadShare(List<LeadShare> lstLeadShare,String strOperation){
        if(strOperation.equalsIgnoreCase( RetailConstants.INSERT_OPERATION )){
            insert lstLeadShare;
        }   
        else  if(strOperation.equalsIgnoreCase( RetailConstants.UPDATE_OPERATION) ){        
            update lstLeadShare;
        }
        else  if(strOperation.equalsIgnoreCase( RetailConstants.UPSERT_OPERATION )){        
            upsert lstLeadShare;
        }
        else if(strOperation.equalsIgnoreCase( RetailConstants.DELETE_OPERATION )){ 
            delete lstLeadShare;
        }
        return lstLeadShare;
    }
/* 
    *This method is a common method to perform dml on Lead  object
    */
    public static List<Lead> dmlLead(List<Lead> lstLead,String strOperation){
        if(strOperation.equalsIgnoreCase( RetailConstants.INSERT_OPERATION )){      
            insert lstLead;
        }   
        else  if(strOperation.equalsIgnoreCase( RetailConstants.UPDATE_OPERATION) ){        
            update lstLead;
        }
        else  if(strOperation.equalsIgnoreCase( RetailConstants.UPSERT_OPERATION )){        
            upsert lstLead;
        }
        else if(strOperation.equalsIgnoreCase( RetailConstants.DELETE_OPERATION )){     
            delete lstLead;
        }
        return lstLead;
    }
}