import { LightningElement, track } from 'lwc';
import getFolder from '@salesforce/apex/Test210.getFolder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TestLwcComponent extends LightningElement {
    @track folderContent = [];
    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Type', fieldName: 'folderType', type: 'text' }
    ];

    handleViewFolderClick() {
        this.folderContent = [];
        
        getFolder()
            .then(result => {
                if (result.startsWith('Error')) {
                    this.showError(result);
                } else {
                    const parsedResult = JSON.parse(result);
                    this.folderContent = parsedResult.value.map(item => ({
                        id: item.id,
                        name: item.name,
                        folderType: item.folder ? 'Folder' : 'File'
                    }));
                }
            })
            .catch(error => {
                this.showError(error.body ? error.body.message : error.message);
            });
    }

    showError(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}
