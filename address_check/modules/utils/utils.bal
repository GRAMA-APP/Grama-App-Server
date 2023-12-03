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

public isolated function generateCustomResponse(int statusCode, string keyForResponse, string valueForResponse) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setPayload({keyForResponse: valueForResponse});
    return response;
}

public isolated function sanitizeAddress(string userInputAddress) returns string {
    string lowerCaseWithoutWhitespace = (userInputAddress.toLowerAscii()).trim(); //Convert to lowercase and remove whitespaces

    string:RegExp r1 = re `^"|"$`;
    lowerCaseWithoutWhitespace = r1.replaceAll(lowerCaseWithoutWhitespace, ""); //Remove Quatations

    string:RegExp r = re ` `;
    string[] splittedAddress = r.split(lowerCaseWithoutWhitespace); //Remove spaces and combine the string
    string sanitizedString = string:'join("", ...splittedAddress);

    return sanitizedString;

}
