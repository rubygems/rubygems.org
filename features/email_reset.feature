@wip
Feature: Email reset
  In order to still use my account after I've changed my email address
  A user
  Should be able to reset the email address associated with my account
  
    Scenario: User resets email address
      Given I have signed in with "email@person.com/password"
      And I am on my edit profile page
      When I fill in "Email address" with "email@newperson.com"
      And I press "Reset email address"
      Then an email entitled "Confirm your email address" should be sent to "email@newperson.com"
      And I should be signed out
      
    Scenario: User confirms new email address
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      And I follow the confirmation link sent to "email@newperson.com"
      Then I should see the message "Your email address has been confirmed"
      And I should be signed in
    
    Scenario: User tries to sign in in after resetting email address without confirmation
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      When I sign in as "email@newperson.com/password"
      Then I should be forbidden
      
    Scenario: User signs in after resetting and confirming email address
      Given I have signed in with "email@person.com/password"
      And I have reset my email address to "email@newperson.com"
      And I follow the confirmation link sent to "email@newperson.com"
      When I return next time
      And I sign in as "email@newperson.com/password"
      Then I should be signed in
      
      