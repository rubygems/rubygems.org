Feature: Email reset
  In order to still use my account after I've changed my email address
  A user
  Should be able to reset the email address associated with my account
  
    Scenario: User resets email address
      Given I have signed in with "email@person.com/password"
      And I am on my edit profile page
      When I fill in "Email address" with "email@newperson.com"
      And I press "Reset email address"
      Then an email entitled "Email address confirmation" should be sent to "email@newperson.com"
      And I should see "You will receive an email within the next few minutes."
      And I should be signed out
    
    Scenario: User tries to reset email with an invalid email address
      Given I have signed in with "email@person.com/password"
      And I am on my edit profile page
      When I fill in "Email address" with "this is an invalid email address"
      And I press "Reset email address"
      Then I should see error messages
    
    Scenario: User confirms new email address
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      And I follow the confirmation link sent to "email@newperson.com"
      Then I should see "Confirmed email and signed in"
      And I should be signed in
    
    Scenario: User tries to sign in in after resetting email address without confirmation
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      When I sign in as "email@newperson.com/password"
      Then I should see "Confirmation email will be resent."
      And an email entitled "Email address confirmation" should be sent to "email@newperson.com"
      
    Scenario: User signs in after resetting and confirming email address
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      And I follow the confirmation link sent to "email@newperson.com"
      When I return next time
      And I sign in as "email@newperson.com/password"
      Then I should be signed in
      
      