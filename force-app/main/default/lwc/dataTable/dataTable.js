import { LightningElement, api } from 'lwc';
 
export default class DataTable extends LightningElement {
    @api accessToken; // Access token received from parent component
 
    // Example data to display (replace with actual data retrieval logic)
    columns = [
        { label: 'Name', fieldName: 'displayName', type: 'text' },
        { label: 'Email', fieldName: 'mail', type: 'email' },
        // Add more columns as needed
    ];
    data = []; // Will be populated with actual data from API call
 
    connectedCallback() {
        if (this.accessToken) {
            this.fetchData();
        }
    }
 
    fetchData() {
        // Example Microsoft Graph API call to fetch user data
        let endpoint = 'https://graph.microsoft.com/v1.0/users';
        fetch(endpoint, {
            headers: {
                'Authorization': 'Bearer ' + this.accessToken
            }
        })
        .then(response => response.json())
        .then(data => {
            this.data = data.value; // Assuming 'value' contains array of user objects
        })
        .catch(error => {
            console.error('Error fetching data:', error);
            // Handle error as needed
        });
    }
}