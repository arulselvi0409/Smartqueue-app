import { LightningElement, api } from 'lwc';
import cancelToken from '@salesforce/apex/CancelTokenController.cancelToken';

export default class CancelTokenButton extends LightningElement {

    @api recordId;

    handleCancel() {

        alert('Button Clicked'); // test

        cancelToken({ tokenId: this.recordId })
        .then(() => {
            alert('Token Cancelled');
            window.location.reload();
        })
        .catch(error => {
            console.error(error);
            alert('Error occurred');
        });

    }
}