public class EmployeeTriggerHandler2  extends TriggerHandler{
    public override void afterUpdate(){
        Map<Id,Employee__c> mapEmp = new Map<Id,Employee__c>();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        Store st = new PromotionDemotion();
        TriggerHelper.RoleMap roleMap = new TriggerHelper.RoleMap();
        List<EmployeeStoreRetail__c> lstEmpStoreRetail = new  List<EmployeeStoreRetail__c>();
        mapEmp = EmployeeTriggerHelper.checkIfProfileIsChanged(( Map<Id,Employee__c>)Trigger.NewMap,( Map<Id,Employee__c>)Trigger.OldMap);
        if(!mapEmp.isEmpty()){
            lstEmpStoreRetail = [SELECT id, Employee__c,Store__c,User__c,SFProfileId__c FROM EmployeeStoreRetail__c WHERE Employee__c IN: mapEmp.keySet()];
            if(!lstEmpStoreRetail.isEmpty()){
                roleMap = TriggerHelper.getEmployeeRoleMapping(lstEmpStoreRetail,Trigger.Old,Trigger.NewMap,Trigger.OldMap);
                lstLeadShare = st.addLeadShare(roleMap);
                lstLeadShare = st.removeLeadShare(roleMap);
            }
        }
    }
}