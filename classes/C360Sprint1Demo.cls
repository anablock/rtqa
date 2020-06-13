/*
* This class is called from the VF page to call external API for C360 Sprint 1 Demo
* Author: Rajesh Meda
*/
public with sharing class C360Sprint1Demo {
    public String addressLine1{get;set;}
    public String addressLine2{get;set;}
    public String city{get;set;}
    public String state{get;set;}
    public String zip{get;set;}
    public String unitType1{get;set;}
    public String unitNumber1{get;set;}
    public String serviceAddressResponse{get;set;}
    public String serviceAvailabilityResponse{get;set;}
    public Long elapsedTime{get;set;}
    public Long elapsedTime2{get;set;}

    public C360Sprint1Demo() {

    }

    public void getServiceAddresses() {
        if (String.isNotBlank(addressLine2)) { addressLine2 = '"' + addressLine2 +'"'; } else { addressLine2 = null; }
        if (String.isNotBlank(unitType1)) { unitType1 = '"' + unitType1 +'"'; } else { unitType1 = null; }
        if (String.isNotBlank(unitNumber1)) { unitNumber1 = '"' + unitNumber1 +'"'; } else { unitNumber1 = null; }
        
        String endPointUrl = 'callout:Service_Addresses';
        String endPointUrl2 = 'callout:Service_Availability';
        Http h = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('client_id','cdd8e82934ea4ceabb27494106af175a');
        req.setHeader('client_secret','775f5e6fDA894A9CbAD6bF7964133fE2');
        req.setHeader('Content-Type','application/json');
        req.setBody('{"customertype": "consumer","mode": "fullAddress","addressLine1": "'+ addressLine1 +'","addressLine2": '+ addressLine2 +',"city": "'+ city +'","state": "'+ state +'","zip": "'+ zip +'","unitType1": '+ unitType1 +',"unitNumber1": '+ unitNumber1 +',"addressId": null}');
   
        Long beforeRequestTime = System.now().getTime();
        HttpResponse res = h.send(req);
        
        serviceAddressResponse = res.getBody();
        Long afterRequestTime = System.now().getTime();
        elapsedTime = afterRequestTime - beforeRequestTime;
        
        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint(endPointUrl2+'?address_id=Sc1f754548&clientName=45678');
        req2.setMethod('GET');
        req2.setTimeout(120000);
        req2.setHeader('client_id','cdd8e82934ea4ceabb27494106af175a');
        req2.setHeader('client_secret','775f5e6fDA894A9CbAD6bF7964133fE2');
        
        Long beforeRequestTime2 = System.now().getTime();
        HttpResponse res2 = h.send(req2);
        
        serviceAvailabilityResponse = res2.getBody();
        Long afterRequestTime2 = System.now().getTime();
        elapsedTime2 = afterRequestTime2 - beforeRequestTime2;
    }   
}