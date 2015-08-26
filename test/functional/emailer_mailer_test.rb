require 'test_helper'

class EmailerMailerTest < ActionMailer::TestCase

  def test_generail_email
     user = 'dummyuser@emailserver.com' 
     email = EmailerMailer.general_email(user,'test subject','test body').deliver   
     assert !ActionMailer::Base.deliveries.empty?

     assert_equal [user], email.to
     assert_equal "test subject", email.subject
     assert_match(/test body/, email.encoded)
  end

  def test_withdraw_note
     user = 'dummyuser@emailserver.com' 
     title = 'dummy title'
     email = EmailerMailer.withdraw_note(user,title).deliver
     assert !ActionMailer::Base.deliveries.empty?

     assert_equal [user], email.to
     assert_equal "#{title} has been withdrawn.", email.subject
     assert_match(/#{title} has been withdrawn/, email.encoded)
  end
end
