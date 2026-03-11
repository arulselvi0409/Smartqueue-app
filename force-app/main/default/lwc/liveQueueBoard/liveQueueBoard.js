import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getQueueDisplay from '@salesforce/apex/NowServingController.getQueueDisplay';

export default class LiveQueueBoard extends LightningElement {

    @api recordId;

    nowServing;
    nextTokens = [];

    wiredResult;
    intervalId;

    @wire(getQueueDisplay, { serviceCenterId: '$recordId' })
    wiredQueue(result) {

        this.wiredResult = result;

        if(result.data){
            this.nowServing = result.data.nowServing;
            this.nextTokens = result.data.nextTokens;
        }

        if(result.error){
            console.error(result.error);
        }
    }

    connectedCallback(){

        this.intervalId = setInterval(() => {

            if(this.wiredResult){
                refreshApex(this.wiredResult);
            }

        }, 5000); // refresh every 5 seconds
    }

    disconnectedCallback(){
        clearInterval(this.intervalId);
    }

}