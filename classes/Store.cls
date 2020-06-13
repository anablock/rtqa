/*
* This is implemented by PromotionDemotion and StoreManagerARSMRole to define methods for add and remove lead shares
*in the event of promotion/demotion and store association add/remove respectively
* Author: Rashmi Thippeswamy
*/
public Interface Store{
	
    List<LeadShare> addLeadShare(Object roleMap);
    List<LeadShare> removeLeadShare(Object roleMap);
}