import ballerina/io;
import ballerina/http;
import ballerina/sql;
import ballerina/jwt;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/regex;
import police_check.utils;

configurable utils:DatabaseConfig PolicedatabaseConfig = ?;


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

            if payload.toJson().role != "gramasewaka"{
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



isolated service / on new http:Listener(9090) {

    private final postgresql:Client db;

    function init() returns error? {
        self.db = check new (PolicedatabaseConfig.host,PolicedatabaseConfig.user,PolicedatabaseConfig.password,PolicedatabaseConfig.database,PolicedatabaseConfig.port);
        io:println("Postgres Database is connected and running successfully...");
    }

    isolated resource function post police_check(string nic_number) returns json|error? {
        sql:ParameterizedQuery query = `SELECT * FROM police_records WHERE nic = ${nic_number}`;
        utils:CriminalRecord userCrimeRecords = check self.db->queryRow(query);
        json[] offenses = <json[]> userCrimeRecords.offense;
        return offenses;
    }


}

