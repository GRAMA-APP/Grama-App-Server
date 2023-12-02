import ballerina/io;
import ballerina/http;
import ballerina/sql;
import ballerina/jwt;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/regex;
import address_check.utils;

configurable utils:DatabaseConfig AddressDatabaseConfig = ?;


public isolated service class RequestInterceptor {
    *http:RequestInterceptor;

    // default resource function, which will be executed for all the requests. 
    // `RequestContext` is used to share data between the interceptors.
    isolated resource function 'default [string... path](
            http:RequestContext ctx,
            http:Request req)
        returns http:NextService|http:Response|error? {
        
        if req.hasHeader("Authorization"){
            string token = check req.getHeader("Authorization");
            string regexPattern = "[\\s]+"; // Regex pattern for one or more whitespace characters

            string[] partsStream = regex:split(token, regexPattern);

            // Process the stream and collect the split parts
            string[] parts = [];
            foreach string part in partsStream {
                parts.push(part);
            }
            token = parts.pop();
            [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(token);

            if payload.toJson().role != "general-user"{
                return utils:generateCustomResponse(401,"Unauthorized Access Point for a General User.");
            }
        }
        else{
            // Handle missing token
            return utils:generateCustomResponse(401,"Invalid Token.");
        }
        
        return ctx.next();
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        maxAge: 84900
    }
}

isolated service / on new http:Listener(9090) {

    private final postgresql:Client db;

    function init() returns error? {
        self.db = check new (AddressDatabaseConfig.host,AddressDatabaseConfig.user,AddressDatabaseConfig.password,AddressDatabaseConfig.database,AddressDatabaseConfig.port);
        io:println("Postgres Database is connected and running successfully...");
    }


    isolated resource function get all_records() returns utils:AddressRecord[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM user_address`;

        // Execute the query using the established Postgres connection
        stream<utils:AddressRecord, sql:Error?> addressStream = self.db->query(query);

        
        return from utils:AddressRecord addressRecord in addressStream
            select addressRecord;
        
    }


    isolated resource function post address_check(utils:AddressRecord userProvidedPayload) returns http:Response|error? {
        sql:ParameterizedQuery query = `SELECT address FROM user_address WHERE nic_number = ${userProvidedPayload.nic_number}`;
        utils:AddressRecord userAddressRecord = check self.db->queryRow(query);
        io:print(userAddressRecord);
        io:println(userProvidedPayload.address);
        if userProvidedPayload.address != userAddressRecord.address{
            return utils:generateCustomResponse(404, "Record mismatch between the provided address and the address stored in governmentDB");
        }
        else{
            return utils:generateCustomResponse(200, "Address Verified");
        }
    }


}
