import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getSharePointFiles from '@salesforce/apex/SPIntegration.getSharePointFiles';
import renameSharePointItem from '@salesforce/apex/SPIntegration.renameSharePointItem';
import deleteSharePointItem from '@salesforce/apex/SPIntegration.deleteSharePointItem';
import getSharePointItemDownloadUrl from '@salesforce/apex/SPIntegration.getSharePointItemDownloadUrl';
import getSharePointItemPreviewUrl from '@salesforce/apex/SPIntegration.getSharePointItemPreviewUrl';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FolderFiles extends LightningElement {
    @api folderId;
    @track files;
    @track error;
    @track isLoading = false;
    wiredFilesResult; // To store the wired result for refresh

    @track columns = [
        {
            type: 'button',
            fieldName: 'name',
            label: 'Name',
            sortable: true,
            typeAttributes: { label: { fieldName: 'name' }, variant: 'base', iconName: { fieldName: 'iconName' } }
        },
        {
            type: 'text',
            fieldName: 'type',
            label: 'Type'
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];

    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'Preview', name: 'preview' },
            { label: 'Rename', name: 'rename' },
            { label: 'Delete', name: 'delete' },
            { label: 'Download', name: 'download' } // New action for download
        ];
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('Action Name:', actionName);
        console.log('Row:', row);

        switch (actionName) {
            case 'preview':
                this.previewItem(row);
                break;
            case 'update':
                this.updateItem(row);
                break;
            case 'rename':
                this.renameItem(row);
                break;
            case 'delete':
                this.deleteItem(row);
                break;
            case 'download':
                this.downloadItem(row); // Handle download action
                break;
            default:
                break;
        }
    }

    previewItem(item) {
        console.log('Previewing Item ID:', item.id);
        getSharePointItemPreviewUrl({ itemId: item.id })
            .then((result) => {
                console.log('Preview URL:', result);
                window.open(result, '_blank');
            })
            .catch((error) => {
                this.showToast('Error', 'Error getting preview URL: ' + error.body.message, 'error');
                console.error('Error getting preview URL:', error);
            });
    }

    updateItem(item) {
        // Logic to update the item
    }

    renameItem(item) {
        const newName = prompt('Enter new name:', item.name);
        if (newName) {
            console.log('Renaming Item ID:', item.id, 'New Name:', newName);
            renameSharePointItem({ itemId: item.id, newName: newName })
                .then(() => {
                    this.showToast('Success', 'Item renamed successfully', 'success');
                    return refreshApex(this.wiredFilesResult);
                })
                .catch(error => {
                    this.showToast('Error', 'Error renaming item: ' + error.body.message, 'error');
                    console.error('Error renaming item:', error);
                });
        }
    }

    deleteItem(item) {
        if (confirm('Are you sure you want to delete this item?')) {
            console.log('Deleting Item ID:', item.id);
            deleteSharePointItem({ itemId: item.id })
                .then(() => {
                    this.showToast('Success', 'Item deleted successfully', 'success');
                    return refreshApex(this.wiredFilesResult);
                })
                .catch(error => {
                    this.showToast('Error', 'Error deleting item: ' + error.body.message, 'error');
                    console.error('Error deleting item:', error);
                });
        }
    }

    downloadItem(item) {
        console.log('Downloading Item ID:', item.id);
        getSharePointItemDownloadUrl({ itemId: item.id })
            .then((result) => {
                console.log('Download URL:', result);
                window.open(result, '_blank');
            })
            .catch((error) => {
                this.showToast('Error', 'Error getting download URL: ' + error.body.message, 'error');
                console.error('Error getting download URL:', error);
            });
    }

    @wire(getSharePointFiles, { folderId: '$folderId' })
    wiredFiles(result) {
        this.wiredFilesResult = result; // Store the result to refresh later
        this.isLoading = true;
        if (result.data) {
            console.log('Wired Files Data:', result.data);
            this.files = JSON.parse(result.data).value.map(item => ({
                id: item.id,
                name: item.name,
                type: item.folder ? 'Folder' : 'File',
                iconName: item.folder ? 'utility:open_folder' : 'utility:file'
            }));
            this.error = undefined;
        } else if (result.error) {
            console.error('Wired Files Error:', result.error);
            this.error = result.error;
            this.files = undefined;
        }
        this.isLoading = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}