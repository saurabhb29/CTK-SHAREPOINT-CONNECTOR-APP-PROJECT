import { LightningElement, track } from 'lwc';
import getAccessToken from '@salesforce/apex/SharePointConnectorController.getAccessToken';
import getSharePointData from '@salesforce/apex/SharePointConnectorController.getSharePointData';

export default class SpDataExposeToSfdc extends LightningElement {
    @track showButton = true;
    @track data = [];
    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Modified By', fieldName: 'modifiedBy', type: 'text' },
        { label: 'Modified', fieldName: 'modified', type: 'date' },
        { label: 'File Size', fieldName: 'fileSize', type: 'number' },
        { label: 'Child Count', fieldName: 'childCount', type: 'number' }
    ];

    handleLogin() {
        const loginWindow = window.open('https://login.microsoftonline.com/', '_blank');

        const timer = setInterval(() => {
            try {
                if (loginWindow.document.URL.includes('https://login.microsoftonline.com/common/oauth2/nativeclient')) {
                    clearInterval(timer);
                    loginWindow.close();
                    this.authenticateUser();
                }
            } catch (e) {
                if (loginWindow.closed) {
                    clearInterval(timer);
                    this.authenticateUser();
                }
            }
        }, 500);
    }

    authenticateUser() {
        getAccessToken()
            .then((token) => {
                if (token) {
                    this.showButton = false;
                    this.fetchData();
                } else {
                    console.error('Failed to authenticate');
                }
            })
            .catch((error) => {
                console.error('Error getting access token: ', error);
            });
    }

    fetchData() {
        getSharePointData()
            .then((result) => {
                this.data = result.map((item, index) => ({ ...item, id: index + 1 }));
            })
            .catch((error) => {
                console.error('Error fetching data: ', error);
            });
    }
}
