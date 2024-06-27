import { LightningElement, track } from 'lwc';
import getAccessToken from '@salesforce/apex/Test4.getAccessToken';
 
const TOKEN_STORAGE_KEY = 'accessToken';
 
export default class CustomButton extends LightningElement {
    @track accessToken;
    @track showDataTable = false;
 
    connectedCallback() {
        // Check if token exists in localStorage on component initialization
        this.accessToken = window.localStorage.getItem(TOKEN_STORAGE_KEY);
        this.showDataTable = !!this.accessToken; // Show data table if token exists
    }
 
    authenticateAndShowData() {
        getAccessToken()
            .then(result => {
                this.accessToken = result;
                this.showDataTable = true;
                // Store token in localStorage
                window.localStorage.setItem(TOKEN_STORAGE_KEY, this.accessToken);
            })
            .catch(error => {
                console.error('Error fetching access token:', error);
                // Handle error as needed
            });
    }
 
    handleLogout() {
        // Clear token from localStorage
        window.localStorage.removeItem(TOKEN_STORAGE_KEY);
        this.accessToken = null;
        this.showDataTable = false;
        // Optionally perform other logout actions like navigating to logout page
    }
}
