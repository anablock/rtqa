import { LightningElement,track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import getStoreDetails from '@salesforce/apex/StoreController.getStoreDetails';
import putStoreInCache from '@salesforce/apex/StoreController.putStoreInCache';
import getStoreFromCache from '@salesforce/apex/StoreController.getStoreFromCache';
import Id from '@salesforce/schema/Store__c.Id';
import LocationDbaName__c from '@salesforce/schema/Store__c.LocationDbaName__c';
import City__c from '@salesforce/schema/Store__c.City__c';
import {getSObjectValue} from '@salesforce/apex';

let i=0;


export default class StoresList extends NavigationMixin(LightningElement) {
    @api storecollection;
    @track url;
    @track error;
    @track storeList;
    @track items = [];
    @track selectOptions =[];
    @track listOptions = [];
    @track defResult = '';
    @track defOption = [];
    @track tempArray = [];   
    @track allOptions = [];
  
   /*  get defResult() {        
        console.log("Default option init.." + this.tempArray);
        return this.tempArray;
    }  */

    connectedCallback() {   
        console.log("init...." + JSON.stringify(this.storecollection));        
        let data = JSON.parse(JSON.stringify([...this.storecollection]));
        let myMap = new Map();
        
        data.forEach(record => {
            this.items.push(record.HomeStore__c, record.Store__c);
            myMap.set(record.Store__c, record.HomeStore__c);            
        })
        console.log(JSON.stringify(this.items));
        let sList = JSON.stringify(this.items);
      
        getStoreDetails({'storesList':sList})
            .then(result => {                        
                result.forEach(element => {
                    var id = getSObjectValue(element, Id);                   
                    var optionValue = getSObjectValue(element, LocationDbaName__c);
                    optionValue = optionValue + "-" + getSObjectValue(element, City__c);
                    this.allOptions.push({key:id, value:optionValue});
                    //Check to see HomestoreLocation and set in
                    if(JSON.stringify(myMap.get(id)) === "true") {
                        this.defOption.push({ key: id, value: optionValue});
                        this.tempArray = this.defOption;   
                    }
                    else {
                       // this.listOptions.push({ value: id, label: optionValue});
                        this.selectOptions.push({ key: id, value: optionValue});                       
                    }
                });

                //this.storeList =  this.listOptions;
                this.defResult = this.tempArray;
               
                               
            })
            .catch(error => {
                this.error = error;                
                console.log("Error in calling store details...." + JSON.stringify(error));
            });  

            
       
    }    

    get storeList() {
        console.log("items......"+ this.items);
        return this.items;
    }

    handleChange(event) {           
            var selValue = ''; 
            //match the selected key with optionslist  
            this.allOptions.forEach(element => {              
                if(element.value == event.target.value)
                    selValue = element.key;                
            })
            //add to cache          
            putStoreInCache({'storeId':selValue})
            .then(result => {
              //do nothing
            })
            .catch(error => {
               this.error = error;                
               console.log("Error in calling...." + JSON.stringify(error));
           });          
    }

    navigateToObjectHome() {
        // Navigate to the Lead object home page.
        console.log("inside navigateTo....");
        var redirectURL = window.location.protocol + "//" + window.location.host + "/lightning/o/home";
        var selValue = this.template.querySelector('lightning-combobox');
        console.log('selected value....' + selValue.value);
        putStoreInCache({'storeId':selValue.value})
         .then(result => {
            console.log('selected value....' + selValue.value);
         })
         .catch(error => {
            this.error = error;                
            console.log("Error in calling...." + JSON.stringify(error));
        }); 

        console.log('URL////' + redirectURL);
        
      
    }


}