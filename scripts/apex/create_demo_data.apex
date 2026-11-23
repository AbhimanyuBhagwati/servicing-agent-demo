// Servicing Agent (demo): test data for a Developer Edition org.
// Run it in Execute Anonymous (Developer Console: Debug > Open Execute Anonymous Window),
// or with the CLI: sf apex run --file scripts/apex/create_demo_data.apex
//
// It creates (only if they are not there):
//   - two test Accounts, "Demo Customer A" (customer ID 1001) and "Demo Customer B" (customer ID 1002).
//     The customer ID is in the standard field Account Number, so no new field is needed.
//   - one test Contact on each Account;
//   - two open Cases on Demo Customer A;
//   - two CaseComments on the first Case: one public (IsPublished = true), one internal (IsPublished = false).
//     The agent must show the public note and never the internal note.
// It always sets the org default row of the custom setting Servicing_Demo_Settings__c:
//   logged-in test customer 1001, "live read down" off, "change no reply" off.
// All values are invented test data. No personal data.

List<Account> existing = [
    SELECT Id, Name, AccountNumber
    FROM Account
    WHERE AccountNumber IN ('1001', '1002') AND Name LIKE 'Demo Customer%'
];

if (existing.isEmpty()) {
    Account customerA = new Account(Name = 'Demo Customer A', AccountNumber = '1001');
    Account customerB = new Account(Name = 'Demo Customer B', AccountNumber = '1002');
    insert new List<Account>{ customerA, customerB };

    insert new List<Contact>{
        new Contact(FirstName = 'Demo', LastName = 'Contact A', AccountId = customerA.Id),
        new Contact(FirstName = 'Demo', LastName = 'Contact B', AccountId = customerB.Id)
    };

    Case slowInternet = new Case(
        AccountId = customerA.Id,
        Subject = 'Slow internet in the evening',
        Status = 'Working',
        Origin = 'Phone',
        Priority = 'Medium'
    );
    Case billQuestion = new Case(
        AccountId = customerA.Id,
        Subject = 'Question on the last bill',
        Status = 'New',
        Origin = 'Web',
        Priority = 'Low'
    );
    insert new List<Case>{ slowInternet, billQuestion };

    insert new List<CaseComment>{
        new CaseComment(
            ParentId = slowInternet.Id,
            CommentBody = 'A technician visit is booked to check the internet line.',
            IsPublished = true
        ),
        new CaseComment(
            ParentId = slowInternet.Id,
            CommentBody = 'INTERNAL: the line test showed noise on the line. Do not share with the customer.',
            IsPublished = false
        )
    };
    System.debug('Servicing demo: test data created. Accounts ' + customerA.Id + ', ' + customerB.Id);
} else {
    System.debug('Servicing demo: the test accounts are already there (' + existing.size() + '). No new records.');
}

// The org default row of the hierarchy custom setting.
Servicing_Demo_Settings__c settings = Servicing_Demo_Settings__c.getOrgDefaults();
if (settings == null || settings.Id == null) {
    settings = new Servicing_Demo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
}
settings.Logged_In_Customer_Id__c = '1001';
settings.Live_Read_Down__c = false;
settings.Change_No_Reply__c = false;
upsert settings;
System.debug('Servicing demo: org default settings: customer 1001, live read down off, change no reply off.');
