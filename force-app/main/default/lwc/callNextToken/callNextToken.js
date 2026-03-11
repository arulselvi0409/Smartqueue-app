import { LightningElement, api } from 'lwc';
import callNextToken from '@salesforce/apex/CallNextTokenController.callNextToken';

export default class CallNextToken extends LightningElement {

    @api recordId;

    handleCallNext() {

        callNextToken({ centerId: this.recordId })
            .then(() => {
                window.location.reload();
            })
            .catch(error => {
                console.error(error);
            });

    }
}