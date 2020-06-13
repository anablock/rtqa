import {LightningElement, api, track, wire} from 'lwc';
import {getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';
import multiSelectHtml from './multiSelectButtons.html';
import multiSelectIE11 from './multiSelectButtonsIE11.html'

export default class MultiSelectButtons extends LightningElement {
    @api objApiName;
    @api fieldApiName;
    @api isIcon ;
    @api buttonType;
    @api label;
    @api markReq;
 

    @track options = [];
    @track error;
    @track showIcon ; 
    @track apiToIconName = {"Call": "call", "SMS": "sms"}
    @track showLabel;
    
    @track largeDeviceSize
    @track mediumDeviceSize
    @track smallDeviceSize

    recordTypeId;
    objfieldApiName;
    isRequired;

    @api
    reset() {
        debugger;
        this.options.forEach(key => {
            key.selected = false;
            key.class =  key.class.replace('selected', 'unselected');
        });
        console.log(this.options);
    }
    @api
    markSelection(value, selection) {
        debugger;
        this.options.forEach(key => {
            if(key.value == value) {
                if(selection != key.selected)  {
                    key.selected = selection;
                    if(key.selected) {
                        key.class = key.class.replace('unselected', 'selected');
                    } else {
                        key.class =  key.class.replace('selected', 'unselected');
                    }
                }
            }
        });
        console.log(this.options);
    }

    @api
    setErrorMessage(errorMsg) {
        debugger;
        this.error = errorMsg;
    }

    @wire(getObjectInfo, {objectApiName: '$objApiName'})
    objectInfo(result) {
        if(result.data) {
            this.isRequired = this.markReq == 'true'? true: false;
            this.showIcon = this.isIcon == 'true'? true: false;
            this.showLabel = this.label == 'none' ? false: true;
            // Field Data
            let fieldData = result.data.fields[this.fieldApiName];
            if(fieldData) {
                if(this.label.length == 0)
                    this.label = fieldData.label;
                this.objfieldApiName = {};
                this.objfieldApiName.fieldApiName = fieldData.apiName;
                this.objfieldApiName.objectApiName = result.data.apiName;
                this.recordTypeId = result.data.defaultRecordTypeId;
            }
            else {
                this.error = 'Please enter valid field api name';
            }
        }
        else if(result.error) {
            if(this.customerType != null || typeof this.customerType === 'undefined')
                this.error = JSON.stringify(result.error);
        }
    }
    
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$objfieldApiName'})
    picklistValues({error, data}) {
        if (data) {
            let picklistOptions = [];
            let curIndex = 1;
            // Picklist values
            data.values.forEach(key => {
                var option = {
                    index: curIndex++,
                    label: key.label, 
                    value: key.value,
                    selected: false,
                    class: 'option-container slds-text-align_center unselected',
                    isAdditionalLabel: false
                };
                if(this.showIcon)
                    option.iconName = "/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#"+this.apiToIconName[key.value];
                if(this.fieldApiName == 'PreferredTimeOfContact__c') {
                    option.isAdditionalLabel = true;
                    option.additionalLabel = key.label.substr(key.label.indexOf(' '), key.label.length);
                    option.label = key.label.substr(0, key.label.indexOf(' '));

                } else if (this.fieldApiName == 'PreferedLanguage__c' && option.value == 'English') {
                    option.selected = true;
                    option.class = 'option-container slds-text-align_center selected';
                }
                
                picklistOptions.push(option);
            });
            this.options = picklistOptions;
        } else if (error) {
            this.error = JSON.stringify(error);
        }
    }

    render() {
        if(this.isIE()) {
            return multiSelectIE11;
        } else {
            return multiSelectHtml;
        }
    }

    connectedCallback() {
        if(this.buttonType == "Large") {
            this.largeDeviceSize = 6;
            if(this.isIE())
                this.largeDeviceSize = "slds-size--6-of-12";
            this.mediumDeviceSize = 6;
            this.smallDeviceSize = 6;
        } else if(this.buttonType == "Medium") {
            this.largeDeviceSize = 3;
            if(this.isIE())
                this.largeDeviceSize = "slds-size--3-of-12";
            this.mediumDeviceSize = 3;
            this.smallDeviceSize = 6;
        } else if(this.buttonType == "Small") {
            this.largeDeviceSize = 1;
            if(this.isIE())
                this.largeDeviceSize = "slds-size--1-of-12";
            this.mediumDeviceSize = 3;
            this.smallDeviceSize = 6;
        } 
    }


    handleValueChange(event) {
        let curValue = event.currentTarget.getAttribute('data-val');
        let eventParam = {"fieldApiName": this.fieldApiName,
                        "picklistValue": curValue
                        };
        this.options.forEach(key =>{
            if(key.value == curValue) {
                key.selected = !key.selected;
                if(key.selected) {
                    key.class = key.class.replace('unselected', 'selected');
                } else {
                    key.class =  key.class.replace('selected', 'unselected');
                }
                eventParam.isSelected = key.selected;
            }
        });
        let selectedEvent = new CustomEvent('valuechange', { detail: eventParam });
        this.dispatchEvent(selectedEvent);
    }

    isIE() {
        var ua = window.navigator.userAgent;
        if(ua.indexOf("MSIE") > -1 || ua.indexOf("Trident") > -1 || ua.indexOf("IE11") > -1) 
            return true;
        else
            return false;
    }

}