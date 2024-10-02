import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { EnclosingTabId, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';

export default class DcTabLabelSetter extends LightningElement {

    label;
    icon;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state?.c__label) {
                this.label = decodeURIComponent(currentPageReference.state?.c__label);
                this.icon = decodeURIComponent(currentPageReference.state?.c__icon);
            }
        }
    }

    @wire(EnclosingTabId)
    enclosingTabId(data) {
        if (this.label) setTabLabel(data, this.label);
        if (this.icon) setTabIcon(data, this.icon);
    }

}