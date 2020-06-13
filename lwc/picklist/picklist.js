import {LightningElement, api, track, wire} from 'lwc';
import {getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';

export default class Picklist extends LightningElement {
    @api objApiName;
    @api fieldApiName;
    @api isNone;
    @api isLabel;
    @api defaultValue;


    @track options = [];
    @track picklistlabel;
    @track error;
    @track variant; 

    recordTypeId;
    objfieldApiName;

    @wire(getObjectInfo, {objectApiName: '$objApiName'})
    objectInfo(result) {
        if(result.data) {
            if(typeof this.defaultValue != 'undefined' && this.defaultValue != null ) {
                let eventParam = {"fieldApiName": this.fieldApiName,
                                "value": this.defaultValue
                                };
                const selectedEvent = new CustomEvent('fieldchange', { detail: eventParam });
                this.dispatchEvent(selectedEvent);
            }
            // Field Data
            let fieldData = result.data.fields[this.fieldApiName];
            if(fieldData) {
                this.picklistlabel = fieldData.label;
            
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
            this.error = JSON.stringify(result.error);
        }
    }
    
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$objfieldApiName'})
    picklistValues({error, data}) {
        if (data) {
            this.isLabel = this.isLabel == 'true'? true: false;
            this.variant = this.isLabel ? 'label-stacked' : 'label-hidden';
            let picklistOptions = [];

            // Picklist values
            data.values.forEach(key => {
                var option = {
                    label: key.label, 
                    value: key.value,
                };
                
                picklistOptions.push(option);
            });
            this.isNone = this.isNone == 'true' ? true : false;
            if(this.isNone) {
                var option = {
                    label: "", 
                    value: "",
                };
                
                picklistOptions.push(option);
            }

            this.options = picklistOptions;

        } else if (error) {
            this.error = JSON.stringify(error);
        }
    }

    handleValueChange(event) {
        let curValue = event.currentTarget.value;
        let eventParam = {"fieldApiName": this.fieldApiName,
                        "value": curValue
                        };
        const selectedEvent = new CustomEvent('fieldchange', { detail: eventParam });
        this.dispatchEvent(selectedEvent);
    }
}