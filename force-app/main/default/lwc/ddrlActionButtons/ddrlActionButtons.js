import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

// Import message service features required for subscribing and the message channel
import { subscribe, MessageContext } from 'lightning/messageService';
import CHECKBOXES_CHANGED_CHANNEL from '@salesforce/messageChannel/ddrlCheckboxesChanged__c';

import getButtons from '@salesforce/apex/DDRL_Action_Buttons_Controller.getButtons';



export default class DdrlActionButtons extends NavigationMixin(LightningElement) {

    @api title
    @api titleIcon;
    @api xconfigId;

    @api recordId;

    selectedRecordIds;
    selectedDcIds;
    parentDcId;

    visibleButtons = [];

    dataReady = false;

    @wire(getButtons,
        {
            configId: '$xconfigId',
        }
    ) records({ error, data }) {
        if (data) {
            console.log(JSON.stringify(data));
            this.visibleButtons = JSON.parse(data).buttons;
        } else if (error) {
            console.log('** Error: ' + error.message);
        }
    }

    // Subscribes this component to the checkboxes changed channel
    @wire(MessageContext) messageContext;
    subscribeToMessageChannel() {
        console.log('Subscribed');
        this.subscription = subscribe(
            this.messageContext,
            CHECKBOXES_CHANGED_CHANNEL,
            (message) => this.handleCheckboxChange(message)
        );
    }

    // Handler for message received from the checkboxes component
    handleCheckboxChange(message) {
        console.log('Checkboxes Changed: ' + JSON.stringify(message));
        this.selectedRecordIds = message.selectedRecordIds;
        this.selectedDcIds = message.selectedDcIds;
        this.parentDcId = message.parentDcId;
        this.configId = message.configId;
        this.configName = message.configName;
        this.keyField = message.keyField;
    }

    handleButtonClick(event) {
        console.log('Button clicked: ' + event.target.dataset.ind);
        const index = parseInt(event.target.dataset.ind);
        let btn = this.visibleButtons[index];
        console.log(JSON.stringify(btn));
        const actionType = btn.actionType__c;
        console.log('Action Type: '+actionType);
        const action = btn.action__c;
        console.log('Action: '+action);
        if (actionType == 'Flow') {
            console.log('Flow action');
            let inputVariables = [
                {
                    name: 'recordIds',
                    type: 'String',
                    value: JSON.stringify(this.selectedRecordIds)
                }, {
                    name: 'dcIds',
                    type: 'String',
                    value: JSON.stringify(this.selectedDcIds)
                }, {
                    name: 'parentRecordId',
                    type: 'String',
                    value: this.recordId
                }, {
                    name: 'parentDcId',
                    type: 'String',
                    value: this.parentDcId
                }
            ];
            console.log('Input Vars: '+JSON.stringify(inputVariables));

            let payload = {
                flowName: action,
                inputVariables: inputVariables
            };
            const payloadJSON = JSON.stringify(payload);
            console.log('Payload: '+payloadJSON);
            const payload64 = btoa(payloadJSON);
            console.log('Payload: ' + payload64);
            this[NavigationMixin.Navigate]({
                type: "standard__navItemPage",
                attributes: {
                    apiName: 'ddrlFlowAction'
                },
                state: {
                    c__pl: payload64
                }
            });
        } else if (actionType == 'url') {
            // Future
        }
        console.log('Button Label: ' + btn.Name + ', Action: ' + action);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.dataReady = true;
    }


}