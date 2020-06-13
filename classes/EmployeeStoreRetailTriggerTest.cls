@isTest
private  class EmployeeStoreRetailTriggerTest {
    private static TestDataFactory.TestWrapper dataFactoryWrap = new TestDataFactory.TestWrapper();
    private static TestDataFactory dataFactory = new TestDataFactory();
    @TestSetup
    static void makeData(){
        
        dataFactoryWrap = dataFactory.createTestData(3);
        System.debug('***** mapRoleVsUsers'+dataFactoryWrap.mapRoleVsUsers);
        System.debug('***** lstStore'+dataFactoryWrap.lstStore);
        System.debug('***** mapEmpRetailStoreVsRole'+dataFactoryWrap.mapEmpRetailStoreVsRole);
        System.debug('***** mapStoreVsMapRoleEmployee'+dataFactoryWrap.mapStoreVsMapRoleEmployee);
        System.debug('***** lstLead'+dataFactoryWrap.lstLead);
    }
    @IsTest
    static void testAddEmpStore(){
        //test lead share add on store addition to an emloyee
        Test.startTest();
        List<EmployeeStoreRetail__c> lstEmpStore = [SELECT id,SFProfileId__c,Store__c,User__c FROM EmployeeStoreRetail__c];
        for(LeadShare ls : [SELECT  id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE LeadId IN(SELECT id FROM Lead)]){
            for(EmployeeStoreRetail__c esr :  lstEmpStore){
                if(esr.SFProfileId__c == RetailConstants.SM_POSITION && ls.Lead.Store__c == esr.Store__c && ls.UserOrGroupId == esr.User__c){
                        System.assertEquals(RetailConstants.LEAD_ACCESS_ALL, ls.LeadAccessLevel,'FAILED');
                }
                else if(esr.SFProfileId__c == RetailConstants.ARSM_POSITION && ls.Lead.Store__c == esr.Store__c && ls.UserOrGroupId == esr.User__c){
                        System.assertEquals(RetailConstants.LEAD_ACCESS_READ, ls.LeadAccessLevel,'FAILED');
                }
            }
        }
        Test.stopTest();
    }
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
        update lstEmpRetail;
        System.debug('*** @@@@ lstEmpRetail'+lstEmpRetail);
        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE Lead.Store__c IN:setStoreIds 
                        AND UserOrGroupId IN: lstUser AND RowCause !='Owner'];
        System.debug('*** '+lstLeadShare);
        SYSTEM.assert(lstLeadShare.isEmpty());
        Test.stopTest();
    }
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
        update lstEmpRetail;
        for(EmployeeStoreRetail__c esr : lstEmpRetail){
            esr.isExpired__c = false;
            lstEmpRetailUpdate.add(esr);
        }
        Test.startTest();
        update lstEmpRetailUpdate;
        System.debug('*** @@@@ lstEmpRetailUpdate'+lstEmpRetailUpdate);
        lstLeadShare = [SELECT id,LeadId,LeadAccessLevel,Lead.Store__c,UserOrGroupId FROM LeadShare WHERE Lead.Store__c IN:setStoreIds 
                        AND UserOrGroupId IN: lstUser AND RowCause !='Owner'];
        System.debug('*** @@@@ lstLeadShare'+lstLeadShare);
        System.debug('*** @@@@ lstLeadShare'+lstLeadShare.size());
        SYSTEM.assert(!lstLeadShare.isEmpty());
        Test.stopTest();
    }

}