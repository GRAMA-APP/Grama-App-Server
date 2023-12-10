import ballerina/http;
import ballerinax/postgresql;
import ballerina/sql;
import ballerinax/postgresql.driver as _;
import ballerina/io;
import grama_cert_api.utils;

public type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

type CertRequestOutput record {|
    string request_id;
    string nic;
    string requested_date;
    string reason;
    string status;
    string requested_by_user;
    string division;
    string nic_front;
    string nic_back;
    string bill;
    string entered_address;
    string reject_reason;
    string name;
    string contact_num;
|};


configurable DatabaseConfig IDdatabaseConfig = ?;


@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        maxAge: 84900
    }
}

service / on new http:Listener(6060) {
    private final postgresql:Client db;

    function init() returns error? {
        postgresql:Options postgresqlOptions = {
            connectTimeout: 10
        };
        self.db = check new (IDdatabaseConfig.host,IDdatabaseConfig.user,IDdatabaseConfig.password,IDdatabaseConfig.database,IDdatabaseConfig.port, options = postgresqlOptions,connectionPool = {maxOpenConnections: 2});
        io:println("Postgres Database is connected and running successfully...");
    }

    // resource function post grama(string user_id, string name) returns string | error? {
       
    //     string result = check insertData(user_id, name);
    //     return result;
    // }



    resource function post mark_as_completed(string request_id) returns sql:ExecutionResult|sql:Error|error?{
        
        sql:ParameterizedQuery query = `UPDATE cert_request SET status = 'completed' WHERE request_id = ${request_id}`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        string message = "Your request has been completed. Please visit the grama niladhari office to collect your certificate.";

        _ = check utils:send_twilio_message(message);

        return result;
    }

    resource function post mark_as_rejected(string request_id, string reject_reason) returns sql:ExecutionResult|sql:Error|error?{
        
        sql:ParameterizedQuery query = `UPDATE cert_request SET status = 'rejected', reject_reason = ${reject_reason} WHERE request_id = ${request_id}`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        string message = "Your request has been rejected. Please contact the grama niladhari office for more information.";

        _ = check utils:send_twilio_message(message);

        return result;
    }

    resource function get all_records_division(string division) returns CertRequestOutput[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM cert_request WHERE division=${division} ORDER BY requested_date DESC`;

        // Execute the query using the established Postgres connection
        stream<CertRequestOutput, sql:Error?> certRequestStream = self.db->query(query);

        
        return from CertRequestOutput request in certRequestStream
            select request;
        
    }
}




