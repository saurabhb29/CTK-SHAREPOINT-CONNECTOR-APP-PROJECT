import { LightningElement, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSharePointFolders from '@salesforce/apex/SPIntegration.getSharePointFolders';
import createSharePointFolder from '@salesforce/apex/SPIntegration.createSharePointFolder';
import uploadSharePointFile from '@salesforce/apex/SPIntegration.uploadSharePointFile';
import renameSharePointItem from '@salesforce/apex/SPIntegration.renameSharePointItem';
import deleteSharePointItem from '@salesforce/apex/SPIntegration.deleteSharePointItem';
import getSharePointItemDownloadUrl from '@salesforce/apex/SPIntegration.getSharePointItemDownloadUrl';
import getSharePointItemPreviewUrl from '@salesforce/apex/SPIntegration.getSharePointItemPreviewUrl';

export default class ExposeSharePointData extends LightningElement {
    @track folders;
    @track error;
    @track isLoading = false;
    @track selectedFolderId;
    @track selectedItemId;
    wiredFoldersResult; // To store the wired result for refresh
    @track columns = [
        {
            type: 'button',
            fieldName: 'name',
            label: 'Name',
            typeAttributes: { label: { fieldName: 'name' }, variant: 'base', iconName: 'utility:open_folder' },
            sortable: true
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

    connectedCallback() {
        this.fetchFolders();
    }

    @wire(getSharePointFolders)
    wiredFolders(result) {
        this.wiredFoldersResult = result;
        const { data, error } = result;
        if (data) {
            const parsedData = JSON.parse(data).value;
            this.folders = this.formatData(parsedData);
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error.body.message;
            this.folders = undefined;
            this.isLoading = false;
            this.showToast('Error', 'Error fetching folders', 'error');
        }
    }

    fetchFolders() {
        this.isLoading = true;
        getSharePointFolders()
            .then(result => {
                const data = JSON.parse(result).value;
                this.folders = this.formatData(data);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching folders:', error);
                this.error = error.body.message;
                this.folders = undefined;
                this.isLoading = false;
                this.showToast('Error', 'Error fetching folders', 'error');
            });
    }

    formatData(data) {
        return data.map(item => ({
            id: item.id,
            name: item.name,
            type: item.folder ? 'Folder' : 'File'
        }));
    }

    handleCreateFolder() {
        const folderName = prompt('Enter folder name:');
        if (folderName) {
            this.isLoading = true;
            createSharePointFolder({ parentId: this.selectedItemId || 'root', folderName: folderName })
                .then(() => {
                    this.showToast('Success', 'Folder created successfully', 'success');
                    return refreshApex(this.wiredFoldersResult); // Refresh data
                })
                .catch(error => {
                    console.error('Error creating folder:', error);
                    this.error = error.body.message;
                    this.isLoading = false;
                    this.showToast('Error', 'Error creating folder', 'error');
                });
        }
    }

    handleUploadFile(event) {
        const file = event.target.files[0];
        if (file) {
            this.isLoading = true;
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                uploadSharePointFile({ parentId: this.selectedItemId || 'root', fileName: file.name, base64Data: base64 })
                    .then(() => {
                        this.showToast('Success', 'File uploaded successfully', 'success');
                        return refreshApex(this.wiredFoldersResult); // Refresh data
                    })
                    .catch(error => {
                        console.error('Error uploading file:', error);
                        this.error = error.body.message;
                        this.isLoading = false;
                        this.showToast('Error', 'Error uploading file', 'error');
                    });
            };
            reader.readAsDataURL(file);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedFolderId = selectedRows[0].id;
            console.log('this.selectedFolderId--->'+this.selectedFolderId);
        } else {
            this.selectedFolderId = null;
        }
    }

    handleRowAction(event) {
        this.selectedFolderId = event.detail.row.id; // Adjust the path based on the actual structure
        console.log('getting folder Id---->' + this.selectedFolderId);

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('Action Name:', actionName);
        console.log('Row:', row);

        switch (actionName) {
            case 'rename':
                this.renameItem(row);
                break;
            case 'delete':
                this.deleteItem(row);
                break;
            case 'download':
                this.downloadItem(row); // Handle download action
                break;
            case 'preview':
                this.previewItem(row); // Handle preview action
                break;
            default:
                break;
        }
    }

    renameItem(item) {
        const newName = prompt('Enter new name:', item.name);
        if (newName) {
            console.log('Renaming Item ID:', item.id, 'New Name:', newName);
            renameSharePointItem({ itemId: item.id, newName: newName })
                .then(() => {
                    this.showToast('Success', 'Item renamed successfully', 'success');
                    return refreshApex(this.wiredFoldersResult); // Refresh data
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
                    return refreshApex(this.wiredFoldersResult); // Refresh data
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}