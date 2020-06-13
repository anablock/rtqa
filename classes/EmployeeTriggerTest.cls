@isTest
/*
* This class is used to test various test cases of promotion/demotion an employee
* Author: Rashmi Thippeswamy
*/
private  class EmployeeTriggerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    /* 
    *This method is used to setup test data of employee,employee store retail,leads and stores
    */
    @TestSetup
    static void makeData(){
    	dataFactoryWrap = dataFactory.createTestData(3,'Empl');
    }
    /* 
    *This method is used to check employee promotion from REP to SM
    */
    @IsTest
    static void testPromoteEmployeeSM(){
        promote(RetailConstants.REP_POSITION,RetailConstants.SM_POSITION);       
    }
    /* 
    *This method is used to check employee promotion from SM to ARSM
    */
    @IsTest
    static void testPromoteEmployeeARSM(){
        promote(RetailConstants.SM_POSITION,RetailConstants.ARSM_POSITION); 
    }
    /* 
    *This method is used to check employee demotion from SM to REP
    */
    @IsTest
    static void testDemoteEmployeeREP(){
         demote(RetailConstants.SM_POSITION,RetailConstants.REP_POSITION); 
    }
    /* 
    *This method is used to check employee demotion from ARSM to SM
    */
    @IsTest
    static void testDemoteEmployeeSM(){
         demote(RetailConstants.ARSM_POSITION,RetailConstants.SM_POSITION); 
    }
    /* 
    *This method is a generic method to facilitate all promotion test cases
    */
    private static void promote(String strPrevPosition,String strCurrentPosition){
        List<Employee__c> lstEmp = new List<Employee__c>();
        List<Lead> lstLead = new List<Lead>();
        Set<Id> setUserIds = new Set<Id>();
        Id repUserId;
        String strAccessLevel;
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        for(Employee__c emp : [SELECT id,SFProfileId__c,User__c FROM Employee__c]){
            if(emp.SFProfileId__c == strPrevPosition){
                emp.SFProfileId__c = strCurrentPosition;
                lstEmp.add(emp);
                setUserIds.add(emp.User__c);
                repUserId = emp.User__c;
            }
        }
        for(Lead l:[SELECT id,OwnerId,Store__c FROM Lead WHERE OwnerId IN:setUserIds]){
            l.OwnerId = repUserId;
            lstLead.add(l);
        }
    	if(repUserId <> null)
        	setUserIds.remove(repUserId);
        Test.startTest();
        //update leads such that only one user is the owner of all leads so that SM or ARSM do not own leads
        update lstLead;
        //update employee's SFProfileId__c to check promotion/demotion
        update lstEmp;
        if(strCurrentPosition == RetailConstants.SM_POSITION){
            strAccessLevel=RetailConstants.LEAD_ACCESS_ALL;
        }
        else if(strCurrentPosition == RetailConstants.ARSM_POSITION){
            strAccessLevel=RetailConstants.LEAD_ACCESS_READ;
        }

        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare
                        WHERE LeadAccessLevel =:strAccessLevel
                        AND UserOrGroupId IN: setUserIds 
                        AND RowCause !='Owner'];
         //check if all the SM and ARSM gained access to leads of their corresponding stores that are not owned by them
        System.assert(!lstLeadShare.isEmpty());
        Test.stopTest();
    }	
    /* 
    *This method is a generic method to facilitate all demotion test scenarios
    */
    private static void demote(String strPrevPosition,String strCurrentPosition){
        Set<Id> setUserIds = new Set<Id>();
        List<Employee__c> lstEmp = new List<Employee__c>();
        List<Lead> lstLead = new List<Lead>();
        Id repUserId;
        String strAccessLevel;
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        for(Employee__c emp : [SELECT id,SFProfileId__c,User__c FROM Employee__c]){
            if(emp.SFProfileId__c == strPrevPosition){
                emp.SFProfileId__c = strCurrentPosition;
                lstEmp.add(emp);
                setUserIds.add(emp.User__c);
            }
        }
        Test.startTest();
        update lstEmp;
        if(strPrevPosition == RetailConstants.SM_POSITION){
            strAccessLevel=RetailConstants.LEAD_ACCESS_ALL;
        }
        else if(strPrevPosition == RetailConstants.ARSM_POSITION){
            strAccessLevel=RetailConstants.LEAD_ACCESS_READ;
        }
        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare
                        WHERE LeadAccessLevel=:strAccessLevel
                        AND UserOrGroupId IN: setUserIds 
                        AND RowCause !='Owner'];
         // Demoted from SM to REP loses all access on leads               
        System.assert(lstLeadShare.isEmpty());
        if(strCurrentPosition == RetailConstants.SM_POSITION){
            lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare
                        WHERE LeadAccessLevel=:RetailConstants.LEAD_ACCESS_ALL
                        AND UserOrGroupId IN: setUserIds 
                        AND RowCause !='Owner'];
         // Demoted from ARSM to SM provisions Read/Write access from Read on all access on leads                        
        System.assert(!lstLeadShare.isEmpty());
        }
        lstEmp = [SELECT id FROM Employee__c WHERE SFProfileId__c=:strPrevPosition];
         // check to asert if all the employees are demoted   
        System.assert(lstEmp.isEmpty()); 
        Test.stopTest();
    }
}