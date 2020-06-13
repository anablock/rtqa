/*
* This classis a test utility to create leads,store,employee,users and employeeretailstore records
* Author: Rashmi Thippeswamy
*/
public without sharing class TestDataFactory {
    public TestDataFactory() {

    }
    public class TestWrapper{
        public TestWrapper(){}
        public Map<String,List<User>> mapRoleVsUsers = new Map<String,List<User>>();
        public List<Store__c> lstStore = new List<Store__c>();  
        public  List<Lead> lstLead = new List<Lead>();
        public List<Employee__c> lstAllEmployees = new List<Employee__c>();
        public Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = new Map<Id,Map<String,List<Employee__c>>>();
        public Map<EmployeeStoreRetail__c,String> mapEmpRetailStoreVsRole = new Map<EmployeeStoreRetail__c,String>();
    }
    private List<User> lstAllUsers = new List<User>();
    private List<Lead> lstAllLeads = new List<Lead>();
    private List<Employee__c> lstAllEmployees = new List<Employee__c>();
    private List<EmployeeStoreRetail__c> lstAllEmpRetailStores = new List<EmployeeStoreRetail__c>();
    private static final String REP_PROFILE = 'Retail RSC Rep'; //Profile Name for the Retail Rep
    private static final String SM_PROFILE = 'Retail SM'; //Profile Name for the Store Manager
    private static final String ARSM_PROFILE = 'Retail ARSM'; //Profile Name for the ARSM
    private Map<String,String> mapProfileToSfProfile     = new map<String, String> {
                                                                                                        REP_PROFILE  => RetailConstants.REP_POSITION,
                                                                                                        SM_PROFILE => RetailConstants.SM_POSITION,
                                                                                                        ARSM_PROFILE => RetailConstants.ARSM_POSITION
                                                                                                };
 /* 
    *This method creates users with Retail RSC Rep,Retail SM and Retail ARSM profiles
    *Arguments: set of profile names,no of users for each profile and unique identifier string
    *Returns: a map of Role =>list of users created
    */
    public  Map<String,List<User>> getRoleVsUsers(Set<String> setProfile ,Integer intUsers,String strUnique){
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Name IN :setProfile];
        List<User> lstUser ;
        User u ;
        Map<String,List<User>> mapRoleVsUsers = new Map<String,List<User>>();
        for(Profile p : lstProfile){
            lstUser = new list<User>();
            for(Integer i=0;i<intUsers;i++){
                u = new User(
                    LastName = 'test'+i+p.Name.deleteWhitespace()+strUnique,
                    Email = 'test'+i+p.Name.deleteWhitespace()+strUnique+'@test.com',
                    Username = 'test'+i+p.Name.deleteWhitespace()+strUnique+'@test.com',
                    CompanyName = 'TEST',
                    Title = 'title',
                    Alias = 'talias',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    profileId = p.id
                );
                lstUser.add(u);
                lstAllUsers.add(u);
            }
            mapRoleVsUsers.put(mapProfileToSfProfile.get(p.Name),lstUser);
        }
        return mapRoleVsUsers;
    }
 /* 
    *This method creates stores 
    */
    public List<Store__c> getStores(Integer intStores,String strUnique){
        List<Store__c> lstStore = new List<Store__c>();
        Store__c store ;
        for(Integer i=0;i<intStores;i++){
            store = new Store__c(Name = strUnique+i);
            lstStore.add(store);
        }
        return lstStore;
    }
 /* 
    *This method creates Employees with home stores for each user and store created previously
    *Arguments: map of Role=>Users so that employees are created based on the roles,List of homestores
    *Returns : map of StoreId=>Role=>Employee__c records 
    */
    public Map<Id,Map<String,List<Employee__c>>> getHomeStoreEmployeesByRole( Map<String,List<User>> mapRoleVsUsers ,List<Store__c> lstStore){
        Employee__c emp;
        Map<String,List<Employee__c>> mapRoleVsEmployee = new Map<String,List<Employee__c>>();
        Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmployee = new Map<Id,Map<String,List<Employee__c>>>();
        List<Employee__c> lstEmp = new List<Employee__c>();
        for(Store__c st : lstStore){
            mapRoleVsEmployee = new Map<String,List<Employee__c>>();
            for(String sRole : mapRoleVsUsers.keySet()){
                lstEmp = new List<Employee__c>();
                for(User u : mapRoleVsUsers.get(sRole) ){
                     emp = new Employee__c(LastName__c = u.LastName,
                                                User__c = u.id,
                                                SFProfileId__c = sRole,
                                                HomeStoreLocation__c =st.id ,
                                                EmployeeId__c = u.id);
                    lstEmp.add(emp);
                    lstAllEmployees.add(emp);
                }
                mapRoleVsEmployee.put(sRole,lstEmp);
            }
            mapStoreVsMapRoleEmployee.put(st.Id, mapRoleVsEmployee);
        }
        return mapStoreVsMapRoleEmployee;
    }
 /* 
    *This method creates Employees Retail Stores to associate employees with multiple stores
    *Arguments : map of StoreId=>Role=>Employee__c records so that all employees are extracted by role,
    *List of stores other than home store for association
    *Returns : map of EmployeeStoreRetail__c records => roles
    */
    public Map<EmployeeStoreRetail__c,String> getEmpRetailStoreByRole(List<Store__c> lstStore,Map<Id,Map<String,List<Employee__c>>> mapStoreVsMapRoleEmp){
        Map<EmployeeStoreRetail__c,String> mapEmpRetailStoreVsRole = new Map<EmployeeStoreRetail__c,String>();
        Map<String,List<EmployeeStoreRetail__c>> mapRoleVsEmpStoreRetail = new Map<String,List<EmployeeStoreRetail__c>>();
        List<Employee__c> lstEmp = new List<Employee__c>();
        EmployeeStoreRetail__c empStore;
        Map<String,List<Employee__c>> mapRoleVsEmployee;
        for(Map<String,List<Employee__c>> mapRoleEmp :mapStoreVsMapRoleEmp.values()){
            for(String strRole:mapRoleEmp.keySet()){
                for(Employee__c emp : mapRoleEmp.get(strRole)){
                    for(Store__c store : lstStore){
                        empStore = new EmployeeStoreRetail__c(Employee__c = emp.id,
                                                                                            Store__c = store.id,
                                                                                            ExternalId__c = emp.id+'-'+store.id);
                        mapEmpRetailStoreVsRole.put(empStore,strRole);
                        lstAllEmpRetailStores.add(empStore);
                    }
                }
            }
        }
        return mapEmpRetailStoreVsRole;
    }
 /* 
    *This method creates Leads 
    *Arguments : map of EmployeeStoreRetail__c records => roles records so that all employees are extracted by role,
    *List of stores other than home store for association
    *Returns : map of EmployeeStoreRetail__c records => roles
    */
    public List<Lead> getLeads(Map<EmployeeStoreRetail__c,String> mapEmpRetailStoreVsRole ,Integer intLeads,String strUnique){
        Lead leadRec = new Lead();
        Id idOwner;
        for(EmployeeStoreRetail__c empStoreRetail : mapEmpRetailStoreVsRole.keySet()){
            if(mapEmpRetailStoreVsRole.get(empStoreRetail) == RetailConstants.REP_POSITION){
                for(Employee__c emp : lstAllEmployees){
                    if(emp.Id == empStoreRetail.Employee__c){
                        idOwner = emp.User__c;
                    }
                }
                for(Integer i=0;i<intLeads;i++){
                    leadRec = new Lead(LastName = strUnique+i,
                                Company = 'Test',
                                Store__c =empStoreRetail.Store__c,
                                OwnerId = idOwner
                            );
                    lstAllLeads.add(leadRec);
                }
            }
        }
        return lstAllLeads;
    }
  /* 
    *This method creates all test data  leads,stores,employees,users,employeestoreretail
    *Arguments : no of records to be created,unique identifier
    *Returns : TestDataFactory.TestWrapper 
    *contains the following:
    *1.mapRoleVsUsers=>Userdata by roles
    *2.lstStore=>list of home stores and other stores
    *3.mapEmpRetailStoreVsRole => Employee Store Retail records by role
    4.mapStoreVsMapRoleEmployee=>Employees by role and stores
    5.lstAllEmployees=>list of all employees
    6.lstLead=>list of all leads
    */
    public TestDataFactory.TestWrapper createTestData(Integer intRecords,String strUnique){
        String strHomeStore = 'home';
        String strStore = 'store';
        String strLead = 'lead';
        TestDataFactory.TestWrapper testDataWrap = new TestDataFactory.TestWrapper();
        //create users
        Map<String,List<User>> mapRoleVsUsers = getRoleVsUsers(mapProfileToSfProfile.keySet()  ,intRecords,strUnique);
        insert lstAllUsers;
        //create homestores
        List<Store__c> lstHomeStore = getStores( intRecords, strUnique+strHomeStore);
        insert lstHomeStore;
        //create Employees
        Map<Id,Map<String,List<Employee__c>>>  mapStoreVsMapRoleEmployee = getHomeStoreEmployeesByRole( mapRoleVsUsers ,lstHomeStore);
        insert lstAllEmployees;
        //create stores
        List<Store__c> lstStore = getStores( intRecords, strUnique+strStore);
        insert lstStore;
        Map<EmployeeStoreRetail__c,String> mapEmpRetailStoreVsRole = getEmpRetailStoreByRole( lstStore, mapStoreVsMapRoleEmployee);
        //create leads
        List<Lead> lstLead = getLeads(mapEmpRetailStoreVsRole ,intRecords,strUnique+strLead);
        insert lstLead;
        //create Employee Store Retail
        insert lstAllEmpRetailStores;
        //Assign to Wrapper
        testDataWrap.mapRoleVsUsers = mapRoleVsUsers;
        testDataWrap.lstStore = lstStore;
        testDataWrap.mapEmpRetailStoreVsRole = mapEmpRetailStoreVsRole;
        testDataWrap.mapStoreVsMapRoleEmployee =mapStoreVsMapRoleEmployee;
        testDataWrap.lstAllEmployees =lstAllEmployees;
        testDataWrap.lstLead=lstLead;
        return testDataWrap;
    }
}