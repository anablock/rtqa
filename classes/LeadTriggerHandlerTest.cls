/*
* This class will cover the test cases for various events and scenarios for Lead trigger
*/
@isTest
public with sharing class LeadTriggerHandlerTest {
    private static final String REP_PROFILE = 'Retail RSC Rep'; //Profile Name for the Retail Rep
    private static final String SM_PROFILE = 'Retail SM'; //Profile Name for the Store Manager
    private static final String ARSM_PROFILE = 'Retail ARSM'; //Profile Name for the ARSM
    private static final  map<String,String> profileIdToSfProfileMap = new map<String, String> (); //Stores the profile Id to SFProfile Name in the map

    private static Store__c store; //Store object to be linked to the Store

    /*
    * This method creates the setup data for the various scenarios of this test class
    */
    @TestSetup
    static void setupData(){
        List<User> userList = createUsers();
        store = createStore();
        List<Employee__c> empList = createEmployees(userList);
        List<EmployeeStoreRetail__c> empStoreList = createEmployeeStore(empList, store);
    }

    /*
    * This method creates the users required for the various scenarios for this tesr class
    */
    private static List<User> createUsers() {
        map<String,String> profileToSfProfileMap = new map<String, String> {
                                                                    REP_PROFILE  => RetailConstants.REP_POSITION,
                                                                    SM_PROFILE => RetailConstants.SM_POSITION,
                                                                    ARSM_PROFILE => RetailConstants.ARSM_POSITION
                                                    };
        list<String> profileNames = new list<String> {REP_PROFILE, SM_PROFILE, ARSM_PROFILE};
        list<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN :profileNames];
        List<User> userList = new list<User>();
        Integer i =0;
        for(Profile prf: profileList) {
            profileIdToSfProfileMap.put(prf.id, profileToSfProfileMap.get(prf.Name));
            User u = new User(
                LastName = 'test'+system.currentTimeMillis(),
                Email = 'test'+system.currentTimeMillis()+'@test.com',
                Username = 'test'+system.currentTimeMillis()+(i++)+'@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                profileId = prf.id
            );
            userList.add(u);
        }
        insert userList;
        return userList;
    }

    /*
    * This method creates the employees for the various users passed in the parameter
    */
    private static List<Employee__c> createEmployees(List<User> userList) {
        List<Employee__c> employeeList = new List<Employee__c>();
        for(User u: userList) {
            Employee__c emp = new Employee__c(LastName__c = u.LastName,
                                                User__c = u.id,
                                                SFProfileId__c = profileIdToSfProfileMap.get(u.ProfileId),
                                                EmployeeId__c = ''+system.currentTimeMillis());
            employeeList.add(emp);
        }
        insert employeeList;
        return employeeList;
    }

    /*
    * This method creates the store record to be linked to the Lead
    */
    private static Store__c createStore() {
        Store__c store = new Store__c(Name = 'Test Store'+system.currentTimeMillis());
        insert store;
        return store;
    }

    /*
    * This method creates the Employee Store association records between Employee and Store 
    */
    private static List<EmployeeStoreRetail__c> createEmployeeStore(List<Employee__c> employeeList, Store__c store) {
        List<EmployeeStoreRetail__c> empStoreList = new List<EmployeeStoreRetail__c>();
        for(Employee__c emp: employeeList) {
            EmployeeStoreRetail__c empStore = new EmployeeStoreRetail__c(Employee__c = emp.id,
                                                Store__c = store.id,
                                                ExternalId__c = emp.id+'-'+store.id);
            empStoreList.add(empStore);
        }
        insert empStoreList;
        return empStoreList;
    }

    /*
    * This method tests the various cases for the Lead insertion
    */
    private static testMethod void testLeadInsert() {
        setupData();
        Test.startTest();
            Lead leadRec = new Lead(LastName = 'test'+system.currentTimeMillis(),
                                    Company = 'Test',
                                    Store__c = store.id
                                    );
            insert leadRec;
        Test.stopTest();

    }

    /*
    * This method tests the various cases for the Lead update
    */
    private static testMethod void testLeadUpdate() {
        setupData();
        Lead leadRec = new Lead(LastName = 'test'+system.currentTimeMillis(),
                                Company = 'Test',
                                Store__c = store.id
                            );
        insert leadRec;
        Store__c store2 = createStore();
        Test.startTest();
            leadRec.Store__c = store2.id;
            update leadRec;
        Test.stopTest();
    }
}