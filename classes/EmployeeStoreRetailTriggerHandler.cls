/*
* This class is called from Employee Store Retail Trigger .It manages store add/remove functionality
* Author: Rashmi Thippeswamy
*/
public class EmployeeStoreRetailTriggerHandler extends TriggerHandler {
    /* 
    *This method is called on Employee Store Retail object's creation to check if IsExpired__c is unchecked and the access
    *is provisioned to all leads of stores if the a store is associated to an employee
    */
    public override void afterInsert(){
        Store st = new StoreManagerARSMRole();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        TriggerHelper.RoleMap roleMap = new TriggerHelper.RoleMap();
        roleMap = TriggerHelper.getEmployeeRoleMapping(Trigger.New,Trigger.Old,Trigger.NewMap,Trigger.OldMap);
        if(roleMap!=NULL){
            lstLeadShare = st.addLeadShare(roleMap);
        }
    }
    /* 
    *This method is called on Employee Store Retail object's update to check if IsExpired__c is checked and the access
    *is unprovisioned to all leads of stores if the a store is removed for an employee
    */
    public override void afterUpdate(){
        Store st = new StoreManagerARSMRole();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        TriggerHelper.RoleMap roleMap = new TriggerHelper.RoleMap();
        roleMap = TriggerHelper.getEmployeeRoleMapping(Trigger.New,Trigger.Old,Trigger.NewMap,Trigger.OldMap);
        if(roleMap!=NULL){
            lstLeadShare = st.removeLeadShare(roleMap);
            lstLeadShare = st.addLeadShare(roleMap);
        }
    }
}