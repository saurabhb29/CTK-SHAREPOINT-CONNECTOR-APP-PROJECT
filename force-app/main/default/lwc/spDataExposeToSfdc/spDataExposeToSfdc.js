import { LightningElement, track } from 'lwc';
import getSharePointData from '@salesforce/apex/SharePointConnectorController.getSharePointData';

export default class SpDataExposeToSfdc extends LightningElement {
    @track data = [];
    @track columns = [
        { label: 'Title', fieldName: 'title' },
        { label: 'Item Name', fieldName: 'itemName' },
        { label: 'Modified', fieldName: 'modified' },
        { label: 'Modified By', fieldName: 'modifiedBy' },
        { label: 'Type', fieldName: 'type' },
        { label: 'File Size', fieldName: 'fileSize', type: 'number' },
        { label: 'Child Count', fieldName: 'childCount', type: 'number' }
    ];

    handleButtonClick() {
        const clientId = '0c4225d7-fbe3-4d1b-b8fd-e5905231e6b0';
        const redirectUri = encodeURIComponent(window.location.href);
        const loginUrl = `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=${clientId}&response_type=code&redirect_uri=${redirectUri}&response_mode=query&scope=openid+profile&state=12345`;
        window.location.href = loginUrl;
    }

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');

        if (code) {
            console.log('Authorization code:', code);
            this.fetchData();
        } else {
            console.log('No authorization code found');
        }
    }

    fetchData() {
        getSharePointData()
            .then(result => {
                console.log('SharePoint data received:', result);
                this.data = result.map(item => ({
                    title: item.fields.Title,
                    itemName: item.fields.ItemName,
                    modified: item.fields.Modified,
                    modifiedBy: item.fields.ModifiedBy,
                    type: item.fields.Type,
                    fileSize: item.fields.FileSize,
                    childCount: item.fields.ChildCount
                }));
                console.log('Mapped data:', this.data);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }
}
