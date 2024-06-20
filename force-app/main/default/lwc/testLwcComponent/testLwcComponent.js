import { LightningElement,track } from 'lwc';
import getAccessToken from '@salesforce/apex/SPIntegration.getAccessToken';

export default class TestLwcComponent extends LightningElement {
    @track isAuthenticated = false;
    @track data = [];
    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Size', fieldName: 'size', type: 'text' },
        { label: 'Last Modified', fieldName: 'lastModified', type: 'text' }
    ];

    connectedCallback() {
        // Check if token exists (e.g., in localStorage)
        this.isAuthenticated = !!localStorage.getItem('accessToken');
        if (this.isAuthenticated) {
            // Optionally, load data upon component initialization if authenticated
            this.loadData();
        }
    }

    authenticate() {
        // Call Apex method to get access token
        getAccessToken()
            .then(result => {
                // Save token securely (e.g., localStorage)
                localStorage.setItem('accessToken', result);

                // Update UI
                this.isAuthenticated = true;

                // Load data upon successful authentication
                this.loadData();
            })
            .catch(error => {
                console.error('Error authenticating:', error);
                // Handle error, display message, etc.
            });
    }

    loadData() {
        // Implement your logic to load SharePoint data
        // Example mock data
        this.data = [
            { id: '1', name: 'Document 1', type: 'Document', size: '1.2 MB', lastModified: '2024-06-20' },
            { id: '2', name: 'Presentation', type: 'Presentation', size: '3.5 MB', lastModified: '2024-06-19' },
            { id: '3', name: 'Spreadsheet', type: 'Spreadsheet', size: '780 KB', lastModified: '2024-06-18' }
        ];
    }

    handleLogout() {
        // Clear token from storage
        localStorage.removeItem('accessToken');
        // Update UI to show authentication button
        this.isAuthenticated = false;
        // Call logout method (if needed) to perform any additional cleanup
        // Example call, replace with your actual logout method if different
        logout()
            .then(result => {
                console.log('Logout successful');
                // Optionally perform additional cleanup or actions upon logout
            })
            .catch(error => {
                console.error('Error during logout:', error);
                // Handle error during logout
            });
    }
}