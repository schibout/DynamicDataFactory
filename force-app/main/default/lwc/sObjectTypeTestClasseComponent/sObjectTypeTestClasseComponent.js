import { LightningElement, wire, track } from 'lwc';
import getSObjectTypeTestClasses from '@salesforce/apex/SObjectTypeTestClasseController.getSObjectTypeTestClasses';
import getHeaderRecords from '@salesforce/apex/SObjectTypeTestClasseController.getHeaderRecords';
import getTableHeader   from '@salesforce/apex/SObjectTypeTestClasseController.getTableHeaders';
import getDataForExport from '@salesforce/apex/SObjectTypeTestClasseController.getDataForExport';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SObjectTypeTestClasseComponent extends LightningElement {
    @track records = [];
    @track columns = [];
    @track error;
    @track isLoading = true;
    @track headerRecords = {};
    @track attributeLabels = {};
    @track wiredRecordsResult;

    connectedCallback() {
        this.columns = [
            { 
                label: 'Name', 
                fieldName: 'nameUrl', 
                type: 'url', 
                typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' },
                sortable: true 
            },
            { label: 'SObject Type', fieldName: 'SObjectType__c', type: 'text', sortable: true },
            { label: 'Line Type', fieldName: 'lineType__c', type: 'text', sortable: true },
            { label: 'Line Order', fieldName: 'LineOrder__c', type: 'number', sortable: true }
        ];
    }

    @wire(getTableHeader)
    wiredHeaderRecords({ error, data }) {
        if (data) {
            this.headerRecords = data;
            this.processAttributeLabels();
        } else if (error) {
            console.error('Error fetching header records:', error);
        }
    }

    processAttributeLabels() {
        const labels = {};
        Object.keys(this.headerRecords).forEach(sObjectType => {
            const headerRecord = this.headerRecords[sObjectType];
            labels[sObjectType] = {};
            for (let i = 1; i <= 40; i++) {
                const fieldName = `Attribute${i}__c`;
                labels[sObjectType][fieldName] = headerRecord[fieldName] || `Attribute ${i}`;
            }
        });
        this.attributeLabels = labels;
    }

    @wire(getSObjectTypeTestClasses)
    wiredSObjectTypeTestClasses(result) {
        this.wiredRecordsResult = result;
        if (result.data) {
            this.records = result.data;
            this.error = undefined;
            this.isLoading = false;
            if (this.records.length > 0) {
                this.updateColumns(this.records[0]);
            }
        } else if (result.error) {
            this.error = result.error;
            this.records = [];
            this.isLoading = false;
        }
    }

    updateColumns(sampleRecord) {
        const dynamicColumns = [
            { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
            { label: 'SObject Type', fieldName: 'SObjectType__c', type: 'text', sortable: true },
            { label: 'Line Type', fieldName: 'lineType__c', type: 'text', sortable: true },
            { label: 'Line Order', fieldName: 'LineOrder__c', type: 'number', sortable: true }
        ];
        const recordSObjectType = sampleRecord.SObjectType__c;
        for (let i = 1; i <= 40; i++) {
            const fieldName = `Attribute${i}__c`;
            if (sampleRecord.hasOwnProperty(fieldName) && sampleRecord[fieldName] !== null) {
                let label = this.attributeLabels[recordSObjectType]?.[fieldName] || `Attribute ${i}`;
                dynamicColumns.push({ label: label, fieldName: fieldName, type: 'text', sortable: true });
            }
        }
        this.columns = dynamicColumns;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredRecordsResult)
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Records refreshed successfully', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Error refreshing records: ' + error.body.message, 'error');
            });
    }

     prepareCSVContent(data) {
        const fields = Object.keys(data[0]);
        const csvRows = [];
        csvRows.push(fields.join(','));
        data.forEach(record => {
            const values = fields.map(field => {
                let value = record[field] || '';
                if (typeof value === 'string' && value.includes(',')) {
                    value = `"${value}"`;
                }
                return value;
            });
            csvRows.push(values.join(','));
        });
        return csvRows.join('\n');
    }

    exportToCSV() {
        this.isLoading = true;
        getDataForExport()
            .then(result => {
                if (result && result.length > 0) {
                    let csvContent = this.prepareCSVContent(result);
                    const downloadLink = document.createElement('a');
                    downloadLink.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvContent);
                    downloadLink.target = '_blank';
                    downloadLink.download = 'SObjectTypeTestClasse_Export.csv';
                    downloadLink.click();
                    this.showToast('Success', 'CSV successfully exported', 'success');
                } else {
                    this.showToast('Info', 'No data to export', 'info');
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = error && error.body && error.body.message ? error.body.message : 'Unknown error';
                this.showToast('Error', 'Error exporting data: ' + errorMessage, 'error');
            });
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}