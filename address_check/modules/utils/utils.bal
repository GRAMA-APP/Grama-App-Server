import ballerina/constraint;
import ballerina/http;

public type AddressRecord record {|
    @constraint:String{
        maxLength: 12,
        minLength: 10
    }
    string nic_number;
    string address;
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
