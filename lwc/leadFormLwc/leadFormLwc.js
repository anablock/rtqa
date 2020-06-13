import { LightningElement, wire, api, track } from 'lwc';
import formFactor from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { NavigationMixin } from 'lightning/navigation';
import getHomeStore from '@salesforce/apex/LeadForm.getHomeStore';
import updateLead from '@salesforce/apex/LeadForm.updateLead';
import getStoreFromOpusId from '@salesforce/apex/LeadForm.getStoreFromOpusId';
import leadFormHtml from './leadFormLwc.html';
import leadFormLwcIE11 from './leadFormLwcIE11.html';

/* Label import starts here */
import Cancel from '@salesforce/label/c.Cancel';
import Accept from '@salesforce/label/c.Accept';
import NewLead from '@salesforce/label/c.NewLead';
import Save from '@salesforce/label/c.Save';
import CustomerConsent from '@salesforce/label/c.CustomerConsent';
import ConsentMessage from '@salesforce/label/c.ConsentMessage';
import EmployeeUseOnly from '@salesforce/label/c.EmployeeUseOnly'
import AdditionalLines from '@salesforce/label/c.AdditionalLines'
import ContactPreferences from '@salesforce/label/c.ContactPreferences'
import CustomerContactDate from '@salesforce/label/c.CustomerContactDate'
import PreferredDayOfContact from '@salesforce/label/c.PreferredDayOfContact'
import PreferredTimeOfContact from '@salesforce/label/c.PreferredTimeOfContact'
import ResetMessage from '@salesforce/label/c.ResetMessage'
import ResetFormFields from '@salesforce/label/c.ResetFormFields'
import RequiredError from '@salesforce/label/c.RequiredError'
import Error from '@salesforce/label/c.Error'
import FollowupDateError from '@salesforce/label/c.FollowupDateError'
import PhoneFormatError from '@salesforce/label/c.PhoneFormatError'

//Spanish Labels
import CustomerConsentSpanish from '@salesforce/label/c.CustomerConsentSpanish';
import ConsentMessageSpanish from '@salesforce/label/c.ConsentMessageSpanish'
import MobilePhoneSpanish from '@salesforce/label/c.MobilePhoneSpanish'
import EmailSpanish from '@salesforce/label/c.EmailSpanish'
import FirstNameSpanish from '@salesforce/label/c.FirstNameSpanish'
import LastNameSpanish from '@salesforce/label/c.LastNameSpanish'
import AcceptSpanish from '@salesforce/label/c.AcceptSpanish'
import CancelSpanish from '@salesforce/label/c.CancelSpanish'
/* Label import ends here */

export default class leadFormLwc extends NavigationMixin(LightningElement) {
    label = {
        Cancel,
        CancelSpanish,
        Accept,
        AcceptSpanish,
        NewLead,
        Save,
        CustomerConsent,
        CustomerConsentSpanish,
        ConsentMessage,
        ConsentMessageSpanish,
        EmployeeUseOnly,
        AdditionalLines,
        ContactPreferences,
        CustomerContactDate,
        PreferredDayOfContact,
        PreferredTimeOfContact,
        ResetMessage,
        ResetFormFields,
        MobilePhoneSpanish,
        EmailSpanish,
        FirstNameSpanish,
        LastNameSpanish,
        RequiredError,
        Error,
        FollowupDateError,
        PhoneFormatError
    };
    @track fieldData = {
        Email: { label: "" },
        MobilePhone: { label: "" },
        FirstName: { label: "" },
        LastName: { label: "" },
        Store__c: { label: "" },
    }
    @track leadRecord = {};
    @track isSpanish = false;
    @track isAccepted = false;
    @track isDesktop;
    @track showSaveDesktop = false;
    @track showSaveMobile = false;
    @track isAdditionalLines = false;
    @track isPreviousCarrier = false;
    @track store = {};
    @track showSpinner = true;
    paramMap = {
        "firstName": "FirstName",
        "lastName": "LastName",
        "phone": "MobilePhone",
        "email": "Email",
        "storeId": "storeId"
    }
    timeoutId; param; renderCount = 0;

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo(result) {
        if (result.data) {
            // Field Data
            this.fieldData = result.data.fields;
        } else if (result.error) {}
    }



    picklistValueChange(event) {
        if (this.leadRecord[event.detail.fieldApiName] == null || typeof this.leadRecord[event.detail.fieldApiName] === 'undefined')
            this.leadRecord[event.detail.fieldApiName] = '';
        if (event.detail.fieldApiName == 'PreferedLanguage__c') {
            if (event.detail.isSelected) {
                let prevValue = this.leadRecord.PreferedLanguage__c;
                this.leadRecord[event.detail.fieldApiName] = event.detail.picklistValue;
                if (prevValue.length > 0)
                    event.currentTarget.markSelection(prevValue, false);
            } else {
                this.leadRecord[event.detail.fieldApiName] = event.detail.picklistValue;
                event.currentTarget.markSelection(event.detail.picklistValue, true);
            }
            this.isSpanish = this.leadRecord.PreferedLanguage__c == 'English' ? false : true;
        } else {
            if (event.detail.isSelected) {
                this.leadRecord[event.detail.fieldApiName] += event.detail.picklistValue + ';';
            } else {
                this.leadRecord[event.detail.fieldApiName] = this.leadRecord[event.detail.fieldApiName].replace(event.detail.picklistValue + ';', '');
            }
            if (event.detail.fieldApiName == 'ProductsDiscussed__c') {
                if (this.leadRecord.ProductsDiscussed__c.indexOf('Postpaid') > -1) {
                    this.isAdditionalLines = true;
                } else
                    this.isAdditionalLines = false;
            }
            if (event.detail.fieldApiName == 'CustomerType__c') {
                if (this.leadRecord.CustomerType__c.indexOf('New Customer') > -1) {
                    this.isPreviousCarrier = true;
                } else
                    this.isPreviousCarrier = false;
            }
        }
    }
    validateForm() {
        let isFormValid = true;
        if (typeof this.leadRecord.NextFollowUpDate__c != 'undefined' && this.leadRecord.NextFollowUpDate__c != null) {
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            if (followupDate <= today) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.Error,
                        message: this.label.FollowupDateError,
                        variant: 'error',
                    }),
                );
                isFormValid = false;
            }
        }
        if (typeof this.leadRecord.ProductsDiscussed__c == 'undefined' && this.leadRecord.ProductsDiscussed__c == null) {
            this.setMultiSelectRequiredError('ProductsDiscussed__c');
            isFormValid = false;
        } else if (this.leadRecord.ProductsDiscussed__c == '') {
            this.setMultiSelectRequiredError('ProductsDiscussed__c');
            isFormValid = false;
        }
        if (typeof this.leadRecord.CustomerType__c == 'undefined' && this.leadRecord.CustomerType__c == null) {
            this.setMultiSelectRequiredError('CustomerType__c');
            isFormValid = false;
        } else if (this.leadRecord.CustomerType__c == '') {
            this.setMultiSelectRequiredError('CustomerType__c');
            isFormValid = false;
        }
        return isFormValid;
    }

    setMultiSelectRequiredError(fieldApiName) {
        this.template.querySelectorAll('c-multi-select-buttons').forEach(key => {
            if (key.fieldApiName == fieldApiName) {
                key.setErrorMessage(this.label.RequiredError);
            }
        });
    }

    handleSubmit(event) {
        event.preventDefault();
        this.showSpinner = true;
        if (!this.isAccepted) {
            console.log(event.detail.fields);
            let curFields = event.detail.fields;
            let leadRec = this.leadRecord;
            Object.keys(curFields).forEach(function(key) {
                console.log(key);
                console.log(curFields[key]);
                leadRec[key] = curFields[key];
            });
            this.leadRecord = leadRec;
            let phone = this.leadRecord.MobilePhone;
            if(!this.validatePhoneNumber(phone)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.Error,
                        message: this.label.PhoneFormatError,
                        variant: 'error'
                    })
                );
            } else {
                this.isAccepted = true;
                this.leadRecord['CallConsent__c'] = 'Yes';
                this.leadRecord['SmsConsent__c'] = 'Yes';
                let overlay = this.template.querySelector('.overlay');
                overlay.style.display = 'none';
                if (this.isDesktop)
                    this.showSaveDesktop = true;
                else
                    this.showSaveMobile = true;
            }
            this.showSpinner = false;
        } else {
            let curFields = event.detail.fields;
            let leadRec = this.leadRecord;
            Object.keys(curFields).forEach(function(key) {
                leadRec[key] = curFields[key];
            });
            this.leadRecord = leadRec;
            this.leadRecord.Company = 'ATT';
            leadRec.Company = 'ATT';
            if (this.validateForm()) {
                this.template.querySelector('lightning-record-edit-form').submit(this.leadRecord)
            }
        }
    }
    handleSuccess(event) {
        this.leadRecord.Id = event.detail.id;
        updateLead({
            leadRecord: this.leadRecord
        })
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead Created',
                    variant: 'success'
                })
            );
            this.showSpinner = false;
            this.navigateToDetail();
        });
    }
    navigateToDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.leadRecord.Id,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }

    handleCancel(event) {
        window.history.back();
    }

    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        //Reset all multi select picklist displayed as buttons
        this.template.querySelectorAll('c-multi-select-buttons').forEach(key => {
            key.reset();
        });
        this.isAdditionalLines = false;
        this.isPreviousCarrier = false;
    }

    populateLeadData() {
        try {
            var toString = Object.prototype.toString;
            let url = window.location;
            let urlString = decodeURI(url);
            let subUrl = urlString.split("?");
            let requiredUrl = '';
            subUrl.forEach(function(row) {
                if (row.indexOf("c__leadDetails") >= 0) {
                    requiredUrl = row.split("&");
                }
            });
            if (requiredUrl != '') {
                const table = requiredUrl.map(pair => pair.split("="));
                const result = {};
                table.forEach(([key, value]) => result[key] = value);
                this.param = result["c__leadDetails"];
                this.populateLead();
                console.log(this.param);
            } else {
                this.fetchHomeStore();
            }
        } catch (e) {
            alert(e.message);
        }
    }

    populateLead() {
        this.param = decodeURIComponent(this.param)
        if (window.navigator.userAgent.indexOf("MSIE") > 0) {
            this.param = this.param.replace("{", "");
            this.param = this.param.replace("}", "");
            var attributes = this.param.split(',');
            let leadRec = this.leadRecord;
            attributes.forEach(function(key) {
                var values = key.split(":");
                leadRec[paramMap[values[0]]] = values[0];
            });
            
            this.leadRecord = leadRec;
        } else  {
            var obj = JSON.parse(this.param);
            console.log(obj);
            this.leadRecord['FirstName'] =  obj.firstName;
            this.leadRecord['LastName']  = obj.lastName;;
            this.leadRecord['MobilePhone'] = this.formatPhoneNumber(obj.phone);
            this.leadRecord['Email'] = obj.email;
            this.leadRecord['storeId'] = obj.storeId;
        } 
        if(this.leadRecord['storeId'] != null && typeof this.leadRecord.storeId != 'undefined') {
            getStoreFromOpusId({
                storeId: this.leadRecord.storeId
            })
            .then(result => {
                if (result) {
                    delete this.leadRecord.storeId;
                    this.populateStore(result);
                }
            });
        } else {
            this.fetchHomeStore();
        }

    }

    fetchHomeStore() {
        getHomeStore()
            .then(result => {
                if (result) {
                    this.populateStore(result);
                }
            });
    }
    populateStore(storeData) {
        this.leadRecord.Store__c = storeData.Id;
        this.store.Id = storeData.Id;
        this.store.Url = "/" + storeData.Id;
        this.store.Name = storeData.Name;
    }

    renderedCallback() {
        this.renderCount++;
        if(this.renderCount > 1) {
            let delay = 300;
            if(this.isIE())
                delay = 500;
            clearTimeout(this.timeoutId); // no-op if invalid id
            this.timeoutId = setTimeout(this.showOverlay.bind(this), delay); // Adjust as necessary
        }
    }
    render() {
        if(this.isIE()) {
         return leadFormLwcIE11;
        } else {
            return leadFormHtml;
        }
    }
    showOverlay() {
        let el = this.template.querySelector('.employeeUse');
        let overlay = this.template.querySelector('.overlay');
        let top = el.offsetTop; 
        overlay.style.top = top + 'px';
        console.log(overlay.style.top);
        overlay.style.height = el.offsetHeight + "px"
        //overlay.style.height = el.clientHeight + "px"
        console.log(overlay.style.height);
        this.showSpinner = false;
    }
    connectedCallback() {
        if (formFactor == 'Large')
            this.isDesktop = true;
        else
            this.isDesktop = false;
        
        this.populateLeadData();
        this.leadRecord.PreferedLanguage__c = "English";
    }

    formatPhoneNumber(strPhone) {
        if (strPhone != null) {
            let match = strPhone.match(/^(\d{3})(\d{3})(\d{4})$/);

            if (match) {
                return '(' + match[1] + ') ' + match[2] + '-' + match[3]
            };
        } else 
            return strPhone;
    }
    validatePhoneNumber(strPhone) {
        var phoneRe = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/; 
        //var digits = strPhone.replace(/\D/g, "");
        return phoneRe.test(strPhone);

    }
    
    isIE() {
        var ua = window.navigator.userAgent;
        if(ua.indexOf("MSIE") > -1 || ua.indexOf("Trident") > -1 || ua.indexOf("IE11") > -1) 
            return true;
        else
            return false;
    }
}