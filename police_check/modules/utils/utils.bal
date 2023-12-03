import ballerina/constraint;
import ballerina/http;

public type CriminalRecord record {|
    string record_id;
    @constraint:String{
        maxLength: 12,
        minLength: 10
    }
    string nic;
    json[] offense;
|};

public type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

public isolated function generateCustomResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setPayload({"Error": message});
    return response;
}

public isolated function validateNICNumber(string nicNumber) returns boolean {
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