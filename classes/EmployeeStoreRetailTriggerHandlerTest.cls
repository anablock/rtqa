@isTest
/*
* This class is used to test various test cases of add/remove store from an employee
* Author: Rashmi Thippeswamy
*/
private  class EmployeeStoreRetailTriggerHandlerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    /* 
    *This method is used to setup test data of employee,employee store retail,leads and stores
    */
    @TestSetup
    static void makeData(){
        dataFactoryWrap = dataFactory.createTestData(1,'EmpStrRetail');
    }
    /* 
    *This method is used to test add store to an employee
    */
    @IsTest
    static void testAddEmpStore(){
        //test lead share add on store addition to an emloyee
        Test.startTest();
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c];
        for(LeadShare ls : [SELECT  id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE LeadId IN(SELECT id FROM Lead)]){
            for(EmployeeStoreRetail__c esr :  lstEmpStore){
                if(esr.SFProfileId__c == RetailConstants.SM_POSITION && ls.Lead.Store__c == esr.Store__c && ls.UserOrGroupId == esr.User__c){
                        System.assertEquals(RetailConstants.LEAD_ACCESS_ALL, ls.LeadAccessLevel,'FAILED');
                        //check lead share to see when an SM is added to a store , then the leadsbelonging to the store are provisioned read/write access to the ARSM
                }
                else if(esr.SFProfileId__c == RetailConstants.ARSM_POSITION && ls.Lead.Store__c == esr.Store__c && ls.UserOrGroupId == esr.User__c){
                        System.assertEquals(RetailConstants.LEAD_ACCESS_READ, ls.LeadAccessLevel,'FAILED');
                        //check lead share to see when an ARSM is added to a store , then the leads belonging to the store are provisioned read access to the ARSM
                }
            }
        }
        Test.stopTest();
    }
    /* 
    *This method is used to test remove store to an employee
    */
    @IsTest
    static void testRemoveEmpStore(){
        //test lead share add on store addition to an emloyee
        List<EmployeeStoreRetail__c> lstEmpRetail = new List<EmployeeStoreRetail__c>();
        Set<Id> setStoreIds = new Set<Id>();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        List<User> lstUser =  [SELECT id FROM User WHERE Alias='talias'];
        for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c WHERE Employee__r.User__c IN: lstUser ]){
            esr.isExpired__c = true;
            setStoreIds.add(esr.Store__c);
            lstEmpRetail.add(esr);
        }
        Test.startTest();
        // remove all the employees of all the stores
        update lstEmpRetail;
        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE Lead.Store__c IN:setStoreIds 
                        AND UserOrGroupId IN: lstUser AND RowCause !='Owner'];
        // resultant should remove all the lead access belonging to all the stores
        SYSTEM.assert(lstLeadShare.isEmpty());
        Test.stopTest();
    }
     /* 
    *This method is used to test adding a store back to an employee after removing from the store
    */
    @IsTest
    static void testAddBackEmpStore(){
        //test lead share add on store addition to an emloyee
        List<EmployeeStoreRetail__c> lstEmpRetail = new List<EmployeeStoreRetail__c>();
        List<EmployeeStoreRetail__c> lstEmpRetailUpdate = new List<EmployeeStoreRetail__c>();
        Set<Id> setStoreIds = new Set<Id>();
        List<LeadShare> lstLeadShare = new List<LeadShare>();
        List<User> lstUser =  [SELECT id FROM User WHERE Alias='talias' ];
        for(EmployeeStoreRetail__c esr :  [SELECT id,isExpired__c,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c 
                                           WHERE Employee__r.User__c IN: lstUser  ]){
            esr.isExpired__c = true;
            setStoreIds.add(esr.Store__c);
            lstEmpRetail.add(esr);
        }
        //remove employee from store
        update lstEmpRetail;
        for(EmployeeStoreRetail__c esr : lstEmpRetail){
            esr.isExpired__c = false;
            lstEmpRetailUpdate.add(esr);
        }
        Test.startTest();
        //add employee back to the store
        update lstEmpRetailUpdate;
        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE Lead.Store__c IN:setStoreIds 
                        AND UserOrGroupId IN: lstUser AND RowCause !='Owner'];
        // all lead access should be re-provisioned back on the store
        SYSTEM.assert(!lstLeadShare.isEmpty());
        Test.stopTest();
    }

}