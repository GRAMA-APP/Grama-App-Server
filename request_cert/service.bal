import ballerina/http;
import ballerinax/postgresql;
import ballerina/sql;
import ballerinax/postgresql.driver as _;
import ballerina/io;
import ballerina/uuid;
import request_cert.utils;

public type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

public type Cert_Request record {|
    string request_id;
    string nic;
    string requested_date;
    string reason;
    string supporting_documents;
    string status;
|};

configurable DatabaseConfig IDdatabaseConfig = ?;


@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        maxAge: 84900
    }
}

service /user\-certificate/v1 on new http:Listener(7070) {
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

    resource function post new\-certificate(string nic, string reason, string document_id) returns sql:ExecutionResult|sql:Error|error?{
        
        uuid:Uuid uuid_request = check uuid:createType1AsRecord();
        //convert uuid to string
        string uuid_request_string = check uuid:toString(uuid_request);
    

        sql:ParameterizedQuery query = `INSERT INTO cert_request(request_id, nic, reason, supporting_documents, requested_by_nic) VALUES (${uuid_request_string},${nic},${reason}, ${document_id},${requested_by_nic})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        string message = "Your request has been submitted. The reference number is " + uuid_request_string + ".";

        _ = check utils:send_twilio_message(message);

        return result;
    }





    resource function get records\-by\-nic(string nic) returns Cert_Request[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM cert_request WHERE requested_by_nic = ${nic}`;

        // Execute the query using the established Postgres connection
        stream<Cert_Request, sql:Error?> certRequestStream = self.db->query(query);

        
        return from Cert_Request request in certRequestStream
            select request;
        
    }
}




