# dropship-online-bulk-import
#### Overview

Script using the UEM REST API to bulk add devices to OPS from a CSV file

#### Usage

1. Update the included devices.csv file with the details of your devices to import, each device will be a new row after the header row and the items should be separated by commas. Please leave the header row as is - do not rename any items in the header or the script will not work.  

   Example:  

   `Serial Number,Tag Name,Device Friendly Name,Model Name`

   `DRTFC6,Dropship, Chris Laptop,Dell G16`

   

2. Run the PowerShell script `DropshipOnlineBulkImport.ps1` and enter the information you are prompted for

   - [ ] UEM API Server
   - [ ] The UUID of the OG you want to add the Dropship Online Devices into - you can get this value when you enable Dropship Online
   - [ ] An Admin UEM username that has rights to interact with the UEM API 
   - [ ] The Corresponding PW
   - [ ] The UEM REST API key you want to use.  

   

3. Once you run the script you will be presented the list of devices to be added as read from the CSV file:

   ![Screenshot 2024-05-30 151905](/images/image1.png)

   

   You will then be prompted if you want to add all of them to the OG specified.   If you click no, nothing with happen, and the script will end.  If you click yes, each device will be added and then a sync to OPS will be initiated.  

   ![Screenshot 2024-05-30 151953](/images/image2.png)

   If there are any serial numbers that already exist in OPS, you will receive the following error.   Any non-duplicate devices will still be added, and the duplicate serial number will be added into the log file.  

   ![Screenshot 2024-05-30 152328](/images/image3.png)

   

After the script completes running, you can run the devices through the Dropship Online workflow, or verify they were added in the Dropship Provisioning UI in the UEM console.

The log file will be created at `%temp%\uem-dropship-import-<date>.log`





















