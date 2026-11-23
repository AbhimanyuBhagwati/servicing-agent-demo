// Servicing Agent (demo), scenario 3: the change is not confirmed.
// Sets the org default row of Servicing_Demo_Settings__c: customer 1001 logged in,
// "live read down" off, "change no reply" ON.
// sf apex run --file scripts/apex/scenario_3_change_no_reply.apex
// Then start a NEW preview session (each read happens one time in a session).
Servicing_Demo_Settings__c s = Servicing_Demo_Settings__c.getOrgDefaults();
if (s == null || s.Id == null) {
    s = new Servicing_Demo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
}
s.Logged_In_Customer_Id__c = '1001';
s.Live_Read_Down__c = false;
s.Change_No_Reply__c = true;
upsert s;
System.debug('Scenario 3: customer 1001, live read down off, change no reply ON.');
