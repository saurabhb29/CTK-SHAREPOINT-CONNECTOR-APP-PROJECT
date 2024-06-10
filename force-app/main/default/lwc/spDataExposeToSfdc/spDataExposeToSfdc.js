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
        { label: 'Child Count', fieldName: 'childCount', type: 'number' }
    ];

    handleLogin() {
        console.log('handleLogin called');
        const loginWindow = window.open('https://login.microsoftonline.com/', '_blank');
        const timer = setInterval(() => {
            if (loginWindow.closed) {
                console.log('Login window closed');
                clearInterval(timer);
                this.authenticateUser();
            }
        }, 1000);
    }

    authenticateUser() {
        console.log('authenticateUser called');
        getAccessToken()
            .then((token) => {
                console.log('Access token received:', token);
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
        console.log('fetchData called');
        getSharePointData()
            .then((result) => {
                console.log('Data fetched:', result);
                this.data = result.map((item, index) => ({ ...item, id: index + 1 }));
            })
            .catch((error) => {
                console.error('Error fetching data: ', error);
            });
    }
}
