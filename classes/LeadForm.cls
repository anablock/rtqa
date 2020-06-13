/*
 * This class will have all the methods for the Lead Capture (New Lead) custom form
 * Author: Reshma Jewrani
 * Created Date: 5/12/2020 
 */
public without sharing class LeadForm {
    
    @AuraEnabled(cacheable=true)
    public static Store__c getHomeStore() {
        //Get platform Cache if available else get home store
        String storeId = StoreController.getStoreFromCache();
        system.debug('From Cache-->'+StoreId);
        if(storeId != null && storeId != '') {
            List<Store__c> storeList = [SELECT id, Name 
                                                        FROM Store__c
                                                        WHERE Id = :storeId];
            if(storeList.size() > 0) {
                return storeList.get(0);
            }
        } else {
            
            Store__c homeStore = new Store__c();
            List<Employee__c> homeStoreList = [SELECT id, HomeStoreLocation__c, HomeStoreLocation__r.Name 
                                                            FROM Employee__c 
                                                            WHERE User__c = :UserInfo.getUserId()];
            if(homeStoreList.size() > 0 && homeStoreList.get(0).HomeStoreLocation__c != null) {
                homeStore.Id = homeStoreList.get(0).HomeStoreLocation__c;
                homeStore.Name = homeStoreList.get(0).HomeStoreLocation__r.Name;
                return homeStore;
            }
        }
        return null;
    }
    @AuraEnabled
    public static Lead updateLead(Lead leadRecord) {
        system.debug(leadRecord);
        leadRecord.IsUnreadByOwner = false;
        update leadRecord;
        return leadRecord;
    }
    @AuraEnabled(cacheable=true)
    public static Store__c getStoreFromOpusId(String storeId) {
        system.debug('storeId--?'+storeId);
        List<Store__c> storeList = [SELECT OpusId__c, id, Name 
                                                        FROM Store__c
                                                        WHERE OpusId__c = :storeId];
        system.debug('storeList--?'+storeList);
        if(storeList.size() > 0) {
            return storeList.get(0);
        } else {
            return getHomeStore();
        }
    }
}