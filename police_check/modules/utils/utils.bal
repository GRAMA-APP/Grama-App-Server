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
