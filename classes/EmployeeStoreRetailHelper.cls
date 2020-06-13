public class EmployeeStoreRetailHelper {
    public class RoleMap{
        public Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrAdd;
        public Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrRem;
        public RoleMap(){
            mapRoleVSmapStoreUsrAdd = new Map<String,Map<Id,Set<Id>>>();
            mapRoleVSmapStoreUsrRem = new Map<String,Map<Id,Set<Id>>>(); 
        }
        
    }
	public static LeadShare createLeadShareInstance(String accessLevel, Id leadId, Id userId) {
        LeadShare leadShareRec = new LeadShare(
                                                LeadAccessLevel = accessLevel, 
                                                LeadId = leadId,
                                                RowCause = Schema.LeadShare.RowCause.Manual,
                                                UserOrGroupId = userId);
        return leadShareRec;
    }
    
    public static EmployeeStoreRetailHelper.RoleMap getEmployeeRoleMapping(List<SObject> lstEmpStoreNewSObj,
                                                                    List<SObject> lstEmpStoreOldSObj,
                                                                    Map<Id,SObject> mapEmpStoreNewSObj,
                                                                    Map<Id,SObject> mapEmpStoreOldSObj){ 
        List<EmployeeStoreRetail__c> lstEmpStoreNew = new List<EmployeeStoreRetail__c>();
        List<EmployeeStoreRetail__c> lstEmpStoreOld =new List<EmployeeStoreRetail__c>();
        Map<Id,EmployeeStoreRetail__c> mapEmpStoreNew = new Map<Id,EmployeeStoreRetail__c>();
        Map<Id,EmployeeStoreRetail__c> mapEmpStoreOld = new Map<Id,EmployeeStoreRetail__c>();                                                                     
        EmployeeStoreRetailHelper.RoleMap roleMap = new EmployeeStoreRetailHelper.RoleMap();
        Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrAdd = new Map<String,Map<Id,Set<Id>>>();
        Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsrRem = new Map<String,Map<Id,Set<Id>>>(); 
        Map<Id,Set<Id>> mapStoreVSuserId = new Map<Id,Set<Id>>();                                                                
        lstEmpStoreNew =(List<EmployeeStoreRetail__c>)lstEmpStoreNewSObj;
        lstEmpStoreOld =(List<EmployeeStoreRetail__c>)lstEmpStoreOldSObj;
        mapEmpStoreNew = (Map<Id,EmployeeStoreRetail__c>)mapEmpStoreNewSObj;
        mapEmpStoreOld = (Map<Id,EmployeeStoreRetail__c>)mapEmpStoreOldSObj;
        for(EmployeeStoreRetail__c empStoreRec : [Select Employee__c, IsExpired__c,Employee__r.User__c, Store__c, Employee__r.SFProfileId__c FROM EmployeeStoreRetail__c WHERE Id IN :lstEmpStoreNew]){
            if(mapEmpStoreOld != NULL && !mapEmpStoreOld.isEmpty()){
                if(mapEmpStoreNew.get(empStoreRec.Id).IsExpired__c == true && mapEmpStoreOld.get(empStoreRec.Id).IsExpired__c == false){
                    mapRoleVSmapStoreUsrRem = createRoleMap(mapRoleVSmapStoreUsrRem,mapStoreVSuserId,empStoreRec);
                }
                else if(mapEmpStoreNew.get(empStoreRec.Id).IsExpired__c == false && mapEmpStoreOld.get(empStoreRec.Id).IsExpired__c == true){
                    mapRoleVSmapStoreUsrAdd = createRoleMap(mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
                }
            }
            else{
            	mapRoleVSmapStoreUsrAdd = createRoleMap(mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
            }
        }
        roleMap.mapRoleVSmapStoreUsrAdd = mapRoleVSmapStoreUsrAdd;
        roleMap.mapRoleVSmapStoreUsrRem = mapRoleVSmapStoreUsrRem;                                                              
        return roleMap;
    }
    
    public static Map<String,Map<Id,Set<Id>>> createRoleMap(Map<String,Map<Id,Set<Id>>> mapRoleVSmapStoreUsr,Map<Id,Set<Id>> mapStoreVSuserId,EmployeeStoreRetail__c empStoreRec){
        
        if(mapRoleVSmapStoreUsr.containsKey(empStoreRec.Employee__r.SFProfileId__c)){
            mapStoreVSuserId = mapRoleVSmapStoreUsr.get(empStoreRec.Employee__r.SFProfileId__c);
            if(mapStoreVSuserId.containsKey(empStoreRec.Store__c)){
                mapStoreVSuserId.get(empStoreRec.Store__c).add(empStoreRec.Employee__r.User__c);
            }
            else{
                mapStoreVSuserId.put(empStoreRec.Store__c,new Set<Id>{empStoreRec.Employee__r.User__c});
            }
        }
        else{
            mapStoreVSuserId = new Map<Id,Set<Id>>();
            mapStoreVSuserId.put(empStoreRec.Store__c,new Set<Id>{empStoreRec.Employee__r.User__c});
            mapRoleVSmapStoreUsr.put(empStoreRec.Employee__r.SFProfileId__c,mapStoreVSuserId);
        }
        return mapRoleVSmapStoreUsr;
    }
    public static List<LeadShare> insertLeadShare(List<LeadShare> lstLeadShare){
        if(!lstLeadShare.isEmpty()){
            insert lstLeadShare;
        }
        return lstLeadShare;
    }
    
    public static List<LeadShare> deleteLeadShare(List<LeadShare> lstLeadShare){
        if(!lstLeadShare.isEmpty()){
            delete lstLeadShare;
        }
        return lstLeadShare;
    }
      
}