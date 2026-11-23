// DEMO SETUP: creates the agent user of the Servicing Agent (demo), with no password,
// and gives it two permission sets: AgentforceServiceAgentUser and Servicing_Agent_Demo_Access.
// Run it only in your own org, after the permission set is deployed. The username that it prints
// goes into default_agent_user (the .agent file) and botUser (aiAgents/...aiAgentDefinition-meta.xml).
Profile p = [SELECT Id FROM Profile WHERE Name = 'Einstein Agent User' LIMIT 1];
String uname = 'servicing.demo.agent@' + UserInfo.getOrganizationId().toLowerCase() + '.ext';
List<User> existing = [SELECT Id, Username FROM User WHERE Username = :uname];
User u;
if (existing.isEmpty()) {
    u = new User(
        Username = uname,
        LastName = 'Servicing Demo Agent',
        FirstName = 'AI',
        Alias = 'sdagent',
        Email = UserInfo.getUserEmail(),
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert u;
} else {
    u = existing[0];
}
List<PermissionSet> sets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('AgentforceServiceAgentUser', 'Servicing_Agent_Demo_Access')];
Set<Id> have = new Set<Id>();
for (PermissionSetAssignment a : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :u.Id]) { have.add(a.PermissionSetId); }
List<PermissionSetAssignment> toAdd = new List<PermissionSetAssignment>();
for (PermissionSet ps : sets) { if (!have.contains(ps.Id)) toAdd.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id)); }
insert toAdd;
System.debug('AGENT_USER ' + uname + ' permsets_found=' + sets.size() + ' added=' + toAdd.size());
