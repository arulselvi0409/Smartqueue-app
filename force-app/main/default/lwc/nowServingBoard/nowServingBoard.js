import { LightningElement, api, wire } from 'lwc';
import getNowServingToken from '@salesforce/apex/NowServingController.getNowServingToken';

export default class NowServingBoard extends LightningElement {

    @api recordId;
    token;

    @wire(getNowServingToken, { centerId: '$recordId' })
    wiredToken({ error, data }) {

        if (data) {
            this.token = data;
        }

        if (error) {
            console.error(error);
        }

    }

}