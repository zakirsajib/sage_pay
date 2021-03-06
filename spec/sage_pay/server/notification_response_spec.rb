require 'spec_helper'

include SagePay::Server

describe NotificationResponse do
  it "should work straight from the factory" do
    lambda {
      notification_response_factory.should be_valid
    }.should_not raise_error
  end

  describe "validations" do
    it { validates_the_presence_of(:notification_response, :status) }
    it { validates_the_presence_of(:notification_response, :redirect_url) }

    it "validates the presence of the status_detail field only if the status is something other than OK" do
      notification_response = notification_response_factory(:status => :ok, :status_detail => nil)
      notification_response.should be_valid

      notification_response = notification_response_factory(:status => :invalid, :status_detail => "Invalid request!")
      notification_response.should be_valid

      notification_response = notification_response_factory(:status => :invalid, :status_detail => "")
      notification_response.should_not be_valid
      notification_response.errors.on(:status_detail).should include("can't be empty")
    end

    it { validates_the_length_of(:notification_response, :redirect_url,  :max => 255) }
    it { validates_the_length_of(:notification_response, :status_detail, :max => 255) }

    it "should allow the status to be one of :ok, :invalid or :error" do
      notification_response = notification_response_factory(:status => :ok)
      notification_response.should be_valid

      notification_response = notification_response_factory(:status => :invalid)
      notification_response.should be_valid

      notification_response = notification_response_factory(:status => :error)
      notification_response.should be_valid

      notification_response = notification_response_factory(:status => :chickens)
      notification_response.should_not be_valid
      notification_response.errors.on(:status).should include("is not in the list")
    end
  end

  describe "#response" do
    it "should produce the expected response for an OK status" do
      notification_response = notification_response_factory(
        :status => :ok,
        :redirect_url => "http://test.host/some/redirect",
        :status_detail => nil
      )
      notification_response.response.should == <<-RESPONSE.chomp
Status=OK\r
RedirectURL=http://test.host/some/redirect
      RESPONSE
    end

    it "should produce the expected response for an invalid status" do
      notification_response = notification_response_factory(
        :status => :invalid,
        :redirect_url => "http://test.host/some/redirect",
        :status_detail => "Totally didn't expect that notification, dude."
      )
      # FIXME: I'm asserting here that I don't have to URI-encode the body
      # here. OK?
      notification_response.response.should == <<-RESPONSE.chomp
Status=INVALID\r
RedirectURL=http://test.host/some/redirect\r
StatusDetail=Totally didn't expect that notification, dude.\r
      RESPONSE
    end
  end
end
