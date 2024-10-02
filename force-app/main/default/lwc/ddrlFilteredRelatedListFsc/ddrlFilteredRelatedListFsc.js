import { LightningElement, api, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/DDRL_Filtered_Related_List_Controller.getRelatedList';
import filterQueryRecords from '@salesforce/apex/DDRL_Filtered_Related_List_Controller.filterQueryRecords';

export default class DdrlFilteredRelatedListFsc extends LightningElement {

    // Inputs
    @api recordId;
    @api objectApiName;

    @api title;
    @api titleIcon;
    @api showCount;
    @api xconfigId;
    @api xdataSourceId;
    @api xdataSourceObjectId;
    @api xindividualIdentityLinkObject;
    @api recordContactField='';

    @api eventField;
    @api filter1Field;
    @api filter2Field;
    @api filter3Field;
    @api filter4Field;

    // Reactive filters from the Flow Screen

    @api get xStartDate() { }
    set xStartDate(value) {
        this.filterTransactions('startDate', value);
    }
    @api get xEndDate() { }
    set xEndDate(value) {
        this.filterTransactions('endDate', value);
    }
    @api get xFilter1Value() { }
    set xFilter1Value(value) {
        this.filterTransactions(this.filter1Field, value);
    }
    @api get xFilter2Value() { }
    set xFilter2Value(value) {
        this.filterTransactions(this.filter2Field, value);
    }
    @api get xFilter3Value() { }
    set xFilter3Value(value) {
        this.filterTransactions(this.filter3Field, value);
    }
    @api get xFilter4Value() { }
    set xFilter4Value(value) {
        this.filterTransactions(this.filter4Field, value);
    }

    filters = {};
    hasFilters = false;

    filterTransactions(param, value) {

        this.filters[param] = value;
        if(value) this.hasFilters = true;

        if(this.hasFilters) {

            this.dataReady = false;

            console.log(JSON.stringify(this.filters));

            filterQueryRecords(
                {
                    recordQuery : this.recordQuery,
                    filters : JSON.stringify(this.filters),
                    eventTimeField : this.eventField
                }
            ).then(result => {
                this._ddrlList = JSON.parse(result);
                this.recordCount = this._ddrlList.length;
                if (this.hasLink) {
                    this.setLinks(this.linkCols);
                } else {
                    this.dataReady = true;
                }
            }).catch(error => {
                console.log('** Error: '+ error.message);
            })

        }

    }


    _ddrlList = [];
    get ddrlList() {
        return this._ddrlList;
    }

    _columns = [];
    get columns() {
        return this._columns;
    }

    keyField;
    recordQuery;
    recordCount;
    hasLinks = false;
    linkCols = [];

    sortedBy;
    sortedDirection;

    dataReady = false;

    @wire(getRelatedList,
        {
            recordId: '$recordId',
            configId: '$xconfigId',
            objectApiName: '$objectApiName',
            dataSourceId: '$xdataSourceId',
            dataSourceObjectId: '$xdataSourceObjectId',
            individualIdentityLinkObject: '$xindividualIdentityLinkObject',
            recordContactField: '$recordContactField'
        }
    ) records({ error, data }) {
        if (data) {
            this._ddrlList = JSON.parse(data.records);
            this.recordCount = this._ddrlList.length;
            this.keyField = data.keyField;
            this.recordQuery = data.recordQuery;
            this.buildColumns(JSON.parse(data.columns));
        } else if (error) {
            console.log('** Error: ' + error.message);
        }
    }

    buildColumns(columnConfigs) {
        let cols = [];

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
                this.linkCols.push(col);

            }

            cols.push(col);
        });

        this._columns = cols;

        if (this.hasLink) {
            this.setLinks(this.linkCols);
        } else {
            this.dataReady = true;
        }

    }

    setLinks(linkCols) {

        const urlPattern = /\{{(.*?)\}}/gm;
            this._ddrlList.forEach(rec => {
                linkCols.forEach(col => {
                    if (col.linkFormat) {
                        let link = col.linkFormat;
                        const linkFields = link.matchAll(urlPattern);
                        for (const m of linkFields) {
                            link = link.replace(m[0], rec[m[1]]);
                        }
                        rec[col.fieldName] = link;
                    }
                });
            });
        this.dataReady = true;
        
    }


    handleSort(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;

        let sortedList = [];
        if(sortDirection == 'asc') {
            sortedList = this._ddrlList.sort((a,b) => (a[fieldName] > b[fieldName]) ? 1 : ((b[fieldName] > a[fieldName]) ? -1 : 0));
        } else {
            sortedList = this._ddrlList.sort((a,b) => (a[fieldName] < b[fieldName]) ? 1 : ((b[fieldName] < a[fieldName]) ? -1 : 0));
        }
        this._ddrlList = [...sortedList];
    }


}