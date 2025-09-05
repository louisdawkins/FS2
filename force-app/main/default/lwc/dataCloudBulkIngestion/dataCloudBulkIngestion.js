import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendData from '@salesforce/apex/DataCloudBulkIngestionCtrl.getCsvData';
import getConnectors from '@salesforce/apex/DataCloudBulkIngestionCtrl.getConnectorList'; 

export default class DataCloudBulkIngestion extends LightningElement {
    connectorList;
    connectorOptions;
    connectorValue;
    
    sourceApiValue;
    objectApiValue;

    fileUploaded;
    fileName;
    fileContent;

    isUploadDisabled = true;

    // Wire Apex method containing Data Cloud Ingestion API list
    @wire(getConnectors)
    ingestionList({ data, error }) {
        if (data) {
            this.connectorList = data;

            // Form combobox options
            var options = [];
            data.forEach(element =>{
                options.push({label: element.Label, value: element.Id})
            })
            this.connectorOptions = options;
        } else if (error) {
            console.log('Error in wire ingestionList:');
            console.log(error)
        }
    }    

    handleConnectorChange(event) {
        this.connectorValue = event.detail.value;

        // Set source and object API values
        for(let obj of this.connectorList) {    
            if(obj.Id === this.connectorValue) {
                this.sourceApiValue = obj.Source_API_Name__c;
                this.objectApiValue = obj.Object_API_Name__c;
            }     
        }
        this.handleEnableUpload();
    }

    handleFileChange(event) {
        if (event.target.files.length > 0) {
          this.fileUploaded = event.target.files[0];
          this.fileName = event.target.files[0].name;
        }
        this.handleEnableUpload();
    }

    handleEnableUpload() {
        if (this.connectorValue && this.fileUploaded) {
            this.isUploadDisabled = false;
        }
    }
      
    handleUploadData() {
        var fileReader = new FileReader();             
        fileReader.onloadend = (() => {
            // Get encoded content from file 
            var fileContents = fileReader.result;
            let base64 = 'base64,';
            var content = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(content);
            //this.fileContent = encodeURIComponent(fileContents);   
            fileContents = decodeURIComponent(escape(window.atob(fileContents)));

            // Split file contents into rows through line breaks
            let rows = fileContents.split(/\r?\n/);
            
            // Check if there's an empty last row due to a trailing newline
            if (rows[rows.length - 1] === '') {
                rows.pop();
            }

            // Get header row and remove spaces from each header value
            let headers = rows[0].split(',');
            let modifiedHeaders = headers.map(header => header.replace(/\s+/g, ''));

            // Replace the header row with the modified headers
            rows[0] = modifiedHeaders.join(',');    
            let modifiedCsvContent = rows.join('\n');

            //console.log(rows[0])
            //console.log(modifiedCsvContent)

            // Encode the modified CSV content to base64
            let encodedModifiedCsvContent = btoa(unescape(encodeURIComponent(modifiedCsvContent)));
            this.fileContent = encodeURIComponent(encodedModifiedCsvContent);

            // Start Data Cloud jobs
            sendData({ encodedCsvData : this.fileContent, objectApiName : this.objectApiValue, sourceApiName : this.sourceApiValue })
            .then(result => {
                console.log(result);

                if(result.success === true) {
                    const toastEvent = new ShowToastEvent({
                        title: 'Upload complete',
                        variant: 'success'
                    })
                    this.dispatchEvent(toastEvent)                    
                } else {
                    const toastEvent = new ShowToastEvent({
                        title: 'Error',
                        message: 'Error location: ' + result.errorLocation,
                        variant: 'error'
                    })
                    this.dispatchEvent(toastEvent)  
                }
            })
            .catch(error => {
                console.error('Error creating ingestion job: ' + JSON.stringify(error));
            });    
        });        

        // Format into base64 encoded data
        fileReader.readAsDataURL(this.fileUploaded); 
    }
}