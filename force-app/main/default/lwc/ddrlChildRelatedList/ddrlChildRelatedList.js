import { LightningElement, api, wire } from 'lwc';

// Import message service features required for publishing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import CHECKBOXES_CHANGED_CHANNEL from '@salesforce/messageChannel/ddrlCheckboxesChanged__c';

import getChildRelatedList from '@salesforce/apex/DDRL_Child_Related_List_Controller.getChildRelatedList';

export default class DdrlChildRelatedList extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api title;
    @api titleIcon;
    @api showCount;
    @api xconfigId;
    @api hideCheckboxes = false;

    _dcrlList = [];
    get dcrlList() {
        return this._dcrlList;
    }

    _columns = [];
    get columns() {
        return this._columns;
    }

    keyField;
    config;
    recordCount;
    parentDcId;

    hasLinks = false;

    dataReady = false;
    get configured() {
        if(this.xconfigId) return true;
        else return false;
    }

    @wire(getChildRelatedList,
        {
            recordId: '$recordId',
            configId: '$xconfigId',
            objectApiName: '$objectApiName'
        }
    ) records({ error, data }) {
        if (data) {
            this._dcrlList = JSON.parse(data.records);
            this.recordCount = this._dcrlList.length;
            this.keyField = data.keyField;
            this.config = JSON.parse(data.config);
            this.parentDcId = data.parentDcId;
            this.buildColumns(JSON.parse(data.columns));
        } else if (error) {
            console.log('** Error: ' + error.message);
        }
    }

    @wire(MessageContext)
    messageContext;

    buildColumns(columnConfigs) {
        let cols = [];
        let linkCols = [];

        columnConfigs.forEach(cc => {
            const col = {
                label: cc.label__c,
                fieldName: cc.Name,
                type: cc.displayType__c.toLowerCase(),
                sortable: true,
                cellAttributes : {
                    alignment : cc.alignment__c
                }
            };

            if(cc.width__c) {
                col.initialWidth = cc.width__c;
            }

            if(col.type == 'text' ) {

                col.wrapText = cc.wrapText__c;

            } else if(col.type == 'number' || col.type == 'percent') {
                
                col.typeAttributes = {
                    minimumFractionDigits : cc.decimalPlaces__c,
                    maximumFractionDigits : cc.decimalPlaces__c
                }

            } else if (col.type == 'currency') {

                col.typeAttributes = {
                    minimumFractionDigits : cc.decimalPlaces__c,
                    maximumFractionDigits : cc.decimalPlaces__c,
                    currencyCode : cc.currencyCode__c
                };

            } else if (col.type == 'date') {

                col.type = 'date-local';
                col.typeAttributes = {
                    day : cc.day__c,
                    month : cc.month__c,
                    year : cc.year__c
                };

            } else if(col.type == 'datetime') {

                col.type = 'date';
                col.typeAttributes = {
                    day : cc.day__c,
                    month : cc.month__c,
                    year : cc.year__c,
                    hour : cc.hour__c,
                    minute : cc.minute__c,
                    second : cc.second__c
                };
                if(cc.timeZone__c) col.typeAttributes.timeZone = cc.timeZone__c;

            }

            if (cc.isLink__c) {

                this.hasLink = true;
                let linkFormat = cc.linkFormat__c;

                col.typeAttributes = {
                    label : {
                        fieldName : col.fieldName
                    }
                };
                col.type = 'url';
                col.linkFormat = linkFormat;
                col.fieldName += '_link';
                linkCols.push(col);

            }

            cols.push(col);
        });

        this._columns = cols;

        if (this.hasLink) {
            const urlPattern = /\{{(.*?)\}}/gm;
            this._dcrlList.forEach(rec => {
                linkCols.forEach(col => {
                    if (col.linkFormat) {
                        let link = col.linkFormat;
                        const linkFields = link.matchAll(urlPattern);
                        for (const m of linkFields) {
                            link = link.replace(m[0], rec[m[1]]);
                            console.log(link);
                        }
                        rec[col.fieldName] = link;
                    }
                });
            });
        }

        this.dataReady = true;
    }

    handleSort(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;

        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;

        let sortedList = [];
        if (sortDirection == 'asc') {
            sortedList = this._dcrlList.sort((a, b) => (a[fieldName] > b[fieldName]) ? 1 : ((b[fieldName] > a[fieldName]) ? -1 : 0));
        } else {
            sortedList = this._dcrlList.sort((a, b) => (a[fieldName] < b[fieldName]) ? 1 : ((b[fieldName] < a[fieldName]) ? -1 : 0));
        }
        this._dcrlList = [...sortedList];
    }

    handleRowSelect(event) {
        let selectedRecordIds = [];
        let selectedDcIds = [];
        event.detail.selectedRows.forEach((selectedRow) => {
            selectedRecordIds.push(selectedRow.Id);
            selectedDcIds.push(selectedRow[this.keyField]);
        });
        const payload = {
            selectedRecordIds : selectedRecordIds,
            selectedDcIds : selectedDcIds,
            configId : this.config.Id,
            configName : this.config.Name,
            parentDcId : this.parentDcId,
            keyField : this.keyField
        };
        console.log(JSON.stringify(payload));
        publish(this.messageContext, CHECKBOXES_CHANGED_CHANNEL, payload);

    }


}