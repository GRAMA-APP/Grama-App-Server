import ballerina/io;
import ballerina/http;
import ballerina/sql;
import ballerina/jwt;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/regex;
import identity.utils;


configurable utils:DatabaseConfig IDdatabaseConfig = ?;


public service class RequestInterceptor {
    *http:RequestInterceptor;

    // default resource function, which will be executed for all the requests. 
    // `RequestContext` is used to share data between the interceptors.
    resource function 'default [string... path](
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

service /identity/v1 on new http:Listener(8080) {

    private final postgresql:Client db;

    function init() returns error? {
        self.db = check new (IDdatabaseConfig.host,IDdatabaseConfig.user,IDdatabaseConfig.password,IDdatabaseConfig.database,IDdatabaseConfig.port,connectionPool = {maxOpenConnections: 5});
        io:println("Postgres Database is connected and running successfully...");
    }

    resource function get all\-records() returns utils:Person[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM person`;

        // Execute the query using the established Postgres connection
        stream<utils:Person, sql:Error?> personStream = self.db->query(query);

        return from utils:Person person in personStream
            select person;
        
    }


    resource function get personal\-record(string nic) returns utils:Person|json|error {
        if utils:validateNICNumber(nic) is false{
            return error("Invalid NIC. Please recheck and submit");
        }

        sql:ParameterizedQuery count_query = `SELECT COUNT(*) FROM person WHERE nic_number = ${nic}`;
        int count = check self.db->queryRow(count_query);
        if (count == 0){
            return {"message": "No Matching Records Found"}.toJson();
        }

        sql:ParameterizedQuery query = `SELECT * FROM person WHERE nic_number = ${nic}`;
        utils:Person|sql:Error person = check self.db->queryRow(query);

        return person;

    }

    resource function post personal\-record(utils:Person newUser) returns sql:ExecutionResult|sql:Error {
        sql:ParameterizedQuery query = `INSERT INTO person VALUES (${newUser.nic_number}, ${newUser.f_name}, ${newUser.mid_name}, ${newUser.l_name}, ${newUser.address}, ${newUser.gender})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }

    resource function get nic\-validate(string nic) returns boolean|error? {
        sql:ParameterizedQuery count_query = `SELECT COUNT(*) FROM person WHERE nic_number = ${nic}`;
        int count = check self.db->queryRow(count_query);
        if (count == 0){
            return false;
        }
       else{
         sql:ParameterizedQuery get_query = `SELECT * FROM person WHERE nic_number = ${nic}`;
        
            utils:Person person = check self.db->queryRow(get_query);
            if (person.nic_number == nic){
                return true;
              }
            else{
                return false;
            }
        }
       
 
      
    }

}
 