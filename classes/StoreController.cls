/*
* This class is a Controller class for all operation on Store__c object
* Author: Mohit Pandey
*/
public with sharing class StoreController {
   

     /**
     *  DESCRIPTION   :    This method is called to get Store Details for each StoreId passed during Login Flow
     */      

    @AuraEnabled(cacheable=true)   
    public static List<Store__c> getStoreDetails(String storesList){
          
        List<String> selectedIdsList = new List<String>();     
        Object[] values = (Object[])System.JSON.deserializeUntyped(storesList);
        if(values.size()>0){         
            for (Object id : values) {
                selectedIdsList.add(string.valueof(id));
            }
        } 
        system.debug('SelectedIdsList is......' + selectedIdsList);
        return [
            SELECT Id, LocationDbaName__c, City__c, Zip__c FROM Store__c WHERE Id IN :selectedIdsList ORDER BY LocationDbaName__c
        ]; 
       
    }

     /**
     *  DESCRIPTION   :    This method is a put/get method to insert selected Store (during Login Flow) in platform session cache
     */  

    @AuraEnabled
    public static void putStoreInCache(String storeId) {
           
        Cache.Session.put('local.SelectedStore.key', storeId);
        system.debug('inserted to cache.....' + storeId);
    }
    
    @AuraEnabled
    public static String getStoreFromCache() {

        String storeId ='';
        system.debug('GET CACHE.....' + Cache.Session.contains('local.SelectedStore.key'));
        if(Cache.Session.contains('local.SelectedStore.key'))
            storeId = (String)Cache.Session.get('local.SelectedStore.key');         
        return storeId;
    }
}