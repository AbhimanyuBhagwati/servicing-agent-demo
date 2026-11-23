// Servicing Agent (demo), scenario 1: the normal status.
// Sets the org default row of Servicing_Demo_Settings__c: customer 1001 logged in,
// "live read down" off, "change no reply" off.
// sf apex run --file scripts/apex/scenario_1_normal.apex
// Then start a NEW preview session (each read happens one time in a session).
Servicing_Demo_Settings__c s = Servicing_Demo_Settings__c.getOrgDefaults();
if (s == null || s.Id == null) {
    s = new Servicing_Demo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
}
s.Logged_In_Customer_Id__c = '1001';
s.Live_Read_Down__c = false;
s.Change_No_Reply__c = false;
upsert s;
System.debug('Scenario 1: customer 1001, live read down off, change no reply off.');
