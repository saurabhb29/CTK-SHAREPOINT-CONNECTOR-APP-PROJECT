// import { LightningElement, track } from 'lwc';
// import authenticate from '@salesforce/apex/Test4.getAccessToken';

// export default class SharePointAuth extends LightningElement {
//     @track showConnectButton = true;

//     handleConnect() {
//         authenticate()
//             .then((result) => {
//                 if (result) {
//                     this.showConnectButton = false;
//                 } else {
//                     // Handle the error case
//                     console.error('Authentication failed');
//                 }
//             })
//             .catch((error) => {
//                 console.error('Error during authentication: ', error);
//             });
//     }
// }


import { LightningElement, track } from 'lwc';
import authenticate from '@salesforce/apex/Test4.getAccessToken';
import sharePointIcon from '@salesforce/resourceUrl/SharepointIcon';

export default class SharePointAuth extends LightningElement {
    @track showConnectButton = true;
    sharePointIconUrl = sharePointIcon;

    handleConnect() {
        authenticate()
            .then((result) => {
                if (result) {
                    this.showConnectButton = false;
                } else {
                    // Handle the error case
                    console.error('Authentication failed');
                }
            })
            .catch((error) => {
                console.error('Error during authentication: ', error);
            });
    }
}