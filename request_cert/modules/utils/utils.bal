import ballerina/log;
import ballerinax/slack;
import ballerinax/twilio;


type SlackConfig record {|
    string authToken;
    string channelName;
|};

configurable SlackConfig slackConfig = ?;

slack:Client slackClient = check new({
    auth: {
        token: slackConfig.authToken
    }
});


type TwilioConfig record {|
    string fromMobile;
    string toMobile;
    string accountSId;
    string authToken;
    string message;
|};

configurable TwilioConfig twillioConfig = ?;


twilio:Client twilioClient = check new ({
    twilioAuth: {
         accountSId: twillioConfig.accountSId,
         authToken: twillioConfig.authToken
    }
});



public function send_slack_message(string nic_number) returns error? {
    _ = check slackClient->postMessage({
        channelName: slackConfig.channelName,
        text: string `Your Certificate for NIC ${nic_number} is Ready.`
    });
}

public function send_twilio_message() returns error? {
    var details = twilioClient->sendSms(twillioConfig.fromMobile, twillioConfig.toMobile, twillioConfig.message);
    //Response is printed as log messages
    if (details is twilio:SmsResponse) {
        log:printInfo("SMS_SID: " + details.sid.toString() + ", Body: " + details.body.toString());
    } else {
        log:printInfo(details.message());
    }
}


