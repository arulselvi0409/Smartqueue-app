import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getNearestCenters from '@salesforce/apex/ServiceCenterLocator.getNearestCenters';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class NearestServiceCenter extends NavigationMixin(LightningElement) {

    @track centers = [];
    @track mapMarkers = [];
    @track error;
    @track selectedType = '';

    // Correct values must match Type__c picklist values
    typeOptions = [
        { label: 'All Services', value: '' },
        { label: 'Clinic', value: 'Clinic' },
        { label: 'Parlor', value: 'Parlor' },
        { label: 'Ration Shop', value: 'Ration Shop' },
        { label: 'Government Office', value: 'Government Office' }
    ];

    connectedCallback() {
        this.getUserLocation();
    }

    getUserLocation() {

        if (navigator.geolocation) {

            navigator.geolocation.getCurrentPosition(
                (position) => {

                    const latitude = position.coords.latitude;
                    const longitude = position.coords.longitude;

                    this.fetchNearestCenters(latitude, longitude);

                },
                () => {
                    this.error = 'Location access denied.';
                }
            );

        } else {
            this.error = 'Geolocation not supported by browser.';
        }
    }

    fetchNearestCenters(lat, long) {

        getNearestCenters({
            userLat: lat,
            userLong: long,
            serviceType: this.selectedType
        })
        .then(result => {

            this.centers = result;

            this.mapMarkers = result.map(center => ({
                location: {
                    Latitude: center.latitude,
                    Longitude: center.longitude
                },
                title: center.Name,
                description: `${center.area} • ${center.distanceFormatted} km`
            }));

            this.error = undefined;

        })
        .catch(error => {
            this.error = error.body?.message;
            this.centers = [];
        });
    }

    handleTypeChange(event) {

        this.selectedType = event.detail.value;

        // Refresh centers after selecting new type
        this.getUserLocation();
    }

    handleTakeToken(event) {

        const centerId = event.currentTarget.dataset.id;

        const defaultValues = encodeDefaultFieldValues({
            Service_Center__c: centerId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Token__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }
}