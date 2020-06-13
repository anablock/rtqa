/*
* This class stores the  various constants being used through the Lead Retail track
*/
public with sharing class RetailConstants {
   public static final String LEAD_ACCESS_READ = 'Read';
   public static final String LEAD_ACCESS_ALL = 'Edit';
   public static final String SM_POSITION = Label.SMProfileName;
   public static final String ARSM_POSITION = Label.ARSMProfileName;
   public static final String REP_POSITION = Label.RepProfileName;
   public static final List<String> SHARE_POSITIONS = new list<String> { SM_POSITION, ARSM_POSITION };
   public static final String LEAD_ROW_CAUSE = 'ATT_LeadShare';
   public static final String LEAD_OWNER = 'Owner';

   public static final String CONTACTED = Label.LeadContacted;
   public static final String CAPTURED = Label.LeadCaptured;
   public static final String CLOSED = 'Closed';
   public static final Double REDISTRIBUTE_THRESHOLD = Double.valueOf(Label.RedistributeThreshold);
   public static final List<String> LEAD_STATUS = new list<String> { CONTACTED, CAPTURED };
       
   public static final String ADD = 'Add';
   public static final String REMOVE = 'Remove';

   public static final String EMPLOYEE_STORE_RETAIL = 'EmployeeStoreRetail__c';
   public static final String EMPLOYEE = 'Employee__c';
   public static final String INSERT_OPERATION = 'insert';
   public static final String UPSERT_OPERATION = 'upsert';
   public static final String DELETE_OPERATION = 'delete';
   public static final String UPDATE_OPERATION = 'update';
   public static final String USER_STRING = 'user';
   public static final String STORE_STRING = 'store';

   //Redistribution Reasons
   public static final String EMPLOYEE_OFFBOARD = Label.EmployeeOffboarded;
   public static final String HOME_STORE_CHANGE = Label.HomeLocationTransfer;
   public static final String EMP_REMOVE_LOCATION = Label.EmployeeLocationRemoved;

  

}