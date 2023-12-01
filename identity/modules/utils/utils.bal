import ballerina/constraint;
import ballerina/http;


public type Person record {|
    @constraint:String {
        maxLength: 12,
        minLength: 10
    }
    string nic_number;
    string f_name;
    string mid_name;
    string l_name;
    string address;
    string gender;
|};

public type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

public function generateCustomResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setPayload({"Error": message});
    return response;
}


public function validateNICNumber(string nicNumber) returns boolean {
  if (nicNumber.length() != 10 && nicNumber.length() != 12) {
    return false;
  }

  if (nicNumber.length() == 10) {
    string:RegExp r = re `\d{9}[vV]`;
    if r.find(nicNumber) is () {
      return false;
    }
  } else {
    string:RegExp r = re `\d{12}`;
    if r.find(nicNumber) is () {
      return false;
    }
  }

  return true;
}
