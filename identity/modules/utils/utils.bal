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
