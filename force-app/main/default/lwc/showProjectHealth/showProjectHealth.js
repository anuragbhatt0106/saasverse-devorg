import { LightningElement, track } from 'lwc';
import getProjectsWithHealth from '@salesforce/apex/ProjectHealthUpdateController.getProjectsWithHealth';

export default class ProjectHealthFilter extends LightningElement {
    @track projects = [];
    @track error;
    @track selectedHealth;
    result;

    connectedCallback() {
        getProjectsWithHealth()
            .then(result => {
                this.result = result;
                console.log('Main result', JSON.stringify(this.result));
                //this.projects = result;
                //this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                console.log('Error in GetProjectsByHealth');
                //this.projects = [];
            });
    }

    handleFilter(event) {
        //const selected = event.target.dataset.health;
        //this.selectedHealth = selected;
        this.selectedHealth = event.target.dataset.health;
        console.log('On color change:', this.selectedHealth);
        this.projects = this.result.filter(project => project.Health__c === this.selectedHealth);

        
    }
}