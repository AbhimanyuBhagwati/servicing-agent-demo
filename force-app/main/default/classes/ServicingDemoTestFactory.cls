/**
 * Test data for the Apex tests of the Servicing Agent (demo). Test only.
 * The same invented test data as scripts/apex/create_demo_data.apex.
 */
@IsTest
public class ServicingDemoTestFactory {

    public static void settings(String customerId, Boolean liveReadDown, Boolean changeNoReply) {
        Servicing_Demo_Settings__c s = new Servicing_Demo_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Logged_In_Customer_Id__c = customerId,
            Live_Read_Down__c = liveReadDown,
            Change_No_Reply__c = changeNoReply
        );
        insert s;
    }

    public static Account account(String name, String customerId) {
        Account a = new Account(Name = name, AccountNumber = customerId);
        insert a;
        insert new Contact(FirstName = 'Demo', LastName = 'Contact ' + customerId, AccountId = a.Id);
        return a;
    }

    /** Account 1001 with two open cases, one public note and one internal note. Account 1002 with no case. */
    public static Account customersWithCases() {
        Account a = account('Demo Customer A', '1001');
        account('Demo Customer B', '1002');
        Case c1 = new Case(AccountId = a.Id, Subject = 'Slow internet in the evening', Status = 'Working', Origin = 'Phone');
        Case c2 = new Case(AccountId = a.Id, Subject = 'Question on the last bill', Status = 'New', Origin = 'Web');
        insert new List<Case>{ c1, c2 };
        insert new List<CaseComment>{
            new CaseComment(ParentId = c1.Id, CommentBody = 'A technician visit is booked for Thursday.', IsPublished = true),
            new CaseComment(ParentId = c1.Id, CommentBody = 'INTERNAL: line test showed noise on the line.', IsPublished = false)
        };
        return a;
    }
}
