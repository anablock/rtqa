/*
* This class is called from the TriggerHelper to facilitate Employee Trigger to handle various scenarios to be covered for all events on Employee Object
* Currently, this class handles check employee promotion/demotion conditions and check if the profile is changed on the Employee
* Author: Rashmi Thippeswamy
*/
public class EmployeeTriggerHelper {
     /* 
    *This method is called on Employee object update to check the conditions for promotion/demotion
    */
    public static TriggerHelper.RoleMap checkEmployeeConditions(TriggerHelper.RoleMap roleMap,EmployeeStoreRetail__c empStoreRec ,Map<Id,Set<Id>> mapStoreVSuserId,Map<Id,Employee__c> mapEmpNew,Map<Id,Employee__c> mapEmpOld){
        //Case 1: Promotion from REP to SM
        if(String.isNotBlank(mapEmpNew.get(empStoreRec.Employee__c).SFProfileId__c) && String.isNotBlank(mapEmpOld.get(empStoreRec.Employee__c).SFProfileId__c)){
            if(mapEmpNew.get(empStoreRec.Employee__c).SFProfileId__c == RetailConstants.SM_POSITION && mapEmpOld.get(empStoreRec.Employee__c).SFProfileId__c  == RetailConstants.REP_POSITION){
                //create a map of( SM Role=>{STORE=>List<Promoted SM Users>})
                roleMap.mapRoleVSmapStoreUsrAdd = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
            }
            //Case 2: Promotion from SM to ARSM
            else if(mapEmpNew.get(empStoreRec.Employee__c).SFProfileId__c== RetailConstants.ARSM_POSITION && mapEmpOld.get(empStoreRec.Employee__c).SFProfileId__c  == RetailConstants.SM_POSITION){
                //create a map of( ARSM Role=>{STORE=>List<Promoted ARSM Users>})
                roleMap.mapRoleVSmapStoreUsrAdd = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrAdd,mapStoreVSuserId,empStoreRec);
            }
            //Case 3: Demotion from SM to REP
            else if(mapEmpNew.get(empStoreRec.Employee__c).SFProfileId__c== RetailConstants.REP_POSITION && mapEmpOld.get(empStoreRec.Employee__c).SFProfileId__c  == RetailConstants.SM_POSITION){
                //create a map of( REP Role=>{STORE=>List<Demoted REP Users>})
                roleMap.mapRoleVSmapStoreUsrRem = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrRem,mapStoreVSuserId,empStoreRec);
            }
            //Case 3: Demotion from  ARSM to SM
            else if(mapEmpNew.get(empStoreRec.Employee__c).SFProfileId__c== RetailConstants.SM_POSITION && mapEmpOld.get(empStoreRec.Employee__c).SFProfileId__c  == RetailConstants.ARSM_POSITION){
                //create a map of( SM Role=>{STORE=>List<Demoted SM Users>})
                roleMap.mapRoleVSmapStoreUsrRem = TriggerHelper.createRoleMap(roleMap.mapRoleVSmapStoreUsrRem,mapStoreVSuserId,empStoreRec);
            }
        } 
        return roleMap; 
    }
     /* 
    *This method is called on Employee object update to check if the SFProfileId__c field on Employee is changed to facilitate Promotion/Demotion
    */
    public static Map<Id,Employee__c> checkIfProfileIsChanged(Map<Id,Employee__c> mapEmpNew,Map<Id,Employee__c> mapEmpOld){
        Map<Id,Employee__c> mapEmployee = new Map<Id,Employee__c>();
        for(Id empId :mapEmpNew.keySet() ){
            if(String.isNotBlank(mapEmpNew.get(empId).SFProfileId__c) && String.isNotBlank(mapEmpOld.get(empId).SFProfileId__c) 
            && mapEmpNew.get(empId).SFProfileId__c != mapEmpOld.get(empId).SFProfileId__c){
                mapEmployee.put(empId,mapEmpNew.get(empId));
            }
        }
        return mapEmployee;
    }
}