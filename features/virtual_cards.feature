Feature: Virtual Cards

  Scenario: Virtual Search
    Given I am signed in as Joe Admin
    And I create Search card "editors+*right+*structure" with content
      """
      {"editor_of":"_self"}
      """
    And I am signed in as Joe User
    And I create card "Scratch" with content "that itch"
    Then the card "Scratch+editors" should contain "Joe User"
