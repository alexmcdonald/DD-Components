import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { EnclosingTabId, closeTab } from 'lightning/platformWorkspaceApi';


export default class DdrlFlowAction extends LightningElement {

    @api flowName;
    @api inputVariables;

    tabId;

    dataReady = false;

    @wire(EnclosingTabId)
    enclosingTabId(data) {
         this.tabId = data;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state?.c__pl) {
                const payload64 = currentPageReference.state?.c__pl;
                const payload = JSON.parse(atob(payload64));
                console.log(JSON.stringify(payload));
                console.log(payload.flowName);
                this.flowName = payload.flowName;
                this.inputVariables = payload.inputVariables;
                this.dataReady = true;
            }
        }
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // set behavior after a finished flow interview
            closeTab(this.tabId);
        }
    }

}