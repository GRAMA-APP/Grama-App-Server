import ballerina/io;
import ballerina/http;
import ballerina/sql;
import ballerina/jwt;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/regex;
import police_check.utils;
import ballerina/time;

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

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        maxAge: 84900
    }
}

isolated service / on new http:Listener(9000) {

    private final postgresql:Client db;

    function init() returns error? {
        self.db = check new (PolicedatabaseConfig.host,PolicedatabaseConfig.user,PolicedatabaseConfig.password,PolicedatabaseConfig.database,PolicedatabaseConfig.port,connectionPool = {maxOpenConnections: 5});
        io:println("Postgres Database is connected and running successfully...");
    }

    isolated resource function post police_check(string nic_number) returns json|http:Response|error? {
        if utils:validateNICNumber(nic_number) is false{
            return utils:generateCustomResponse(404, "Invalid NIC Number. Please Recheck and Submit.");
        }
        sql:ParameterizedQuery query_1 = `SELECT COUNT(*) FROM police_records WHERE nic = ${nic_number}`;
        int userRecordCount = check self.db->queryRow(query_1);
        if userRecordCount > 0{
            sql:ParameterizedQuery query_2 = `SELECT * FROM police_records WHERE nic = ${nic_number}`;
            utils:CriminalRecord userCrimeRecords = check self.db->queryRow(query_2);
            json[] offenses = <json[]> userCrimeRecords.offense;

            json recentOffense = <json> offenses.pop();
            io:StringReader sr = new(<string> recentOffense, encoding = "UTF-8");
            json j = check sr.readJson();
            io:println(j.timestamp);

            // Extract timestamp from the JSON object
            string timestampString = check j.timestamp;
            timestampString = timestampString + "Z";

            //Parse timestamp string into time:Time
            time:Utc|time:Error utc = time:utcFromString(timestampString);

            // Get current timestamp
            time:Utc utcNow = time:utcNow();

            // Calculate the duration between the timestamps
            time:Seconds seconds = time:utcDiffSeconds(utcNow, check utc);
            decimal years = seconds/31536000;
            if <int>years < 1{
                //The most recent offense occued less than one year: Contact the police station for confirmation
                return false;
            }
            else{
                //The most recent offense occued more than one year ago. Clear to issue the certificate
                return true;
            }
            
        }
        return true;
    }


}

