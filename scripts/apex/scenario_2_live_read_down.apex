// Servicing Agent (demo), scenario 2: the live read is down.
// Sets the org default row of Servicing_Demo_Settings__c: customer 1001 logged in,
// "live read down" ON, "change no reply" off.
// sf apex run --file scripts/apex/scenario_2_live_read_down.apex
// Then start a NEW preview session (each read happens one time in a session).
Servicing_Demo_Settings__c s = Servicing_Demo_Settings__c.getOrgDefaults();
if (s == null || s.Id == null) {
    s = new Servicing_Demo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
}
s.Logged_In_Customer_Id__c = '1001';
s.Live_Read_Down__c = true;
s.Change_No_Reply__c = false;
upsert s;
System.debug('Scenario 2: customer 1001, live read down ON, change no reply off.');
