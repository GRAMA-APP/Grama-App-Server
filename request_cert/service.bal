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


type CertRequestInput record{|
    string nic;
    string reason;
    string nic_front;
    string nic_back;
    string bill;
    string uid;
    string division;
    string entered_address;
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

service / on new http:Listener(7070) {
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

    resource function post insert_data(CertRequestInput userProvidedPayload) returns sql:ExecutionResult|sql:Error|error?{
        
        uuid:Uuid uuid_request = check uuid:createType1AsRecord();
        //convert uuid to string
        string uuid_request_string = check uuid:toString(uuid_request);
    

        sql:ParameterizedQuery query = `INSERT INTO cert_request(request_id, nic, reason, nic_front,nic_back,bill, requested_by_user, division, entered_address, name, contact_num) VALUES (${uuid_request_string},${userProvidedPayload.nic},${userProvidedPayload.reason}, ${userProvidedPayload.nic_front},${userProvidedPayload.nic_back},${userProvidedPayload.bill},${userProvidedPayload.uid},${userProvidedPayload.division},${userProvidedPayload.entered_address},${userProvidedPayload.name},${userProvidedPayload.contact_num})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        string message = "Your request has been submitted. The reference number is " + uuid_request_string + ".";

        _ = check utils:send_twilio_message(message);

        return result;
    }





    resource function get all_records_by_nic(string nic) returns CertRequestOutput[]|error {

        // Define the SQL query to retrieve all records from the 'person' table
        sql:ParameterizedQuery query = `SELECT * FROM cert_request WHERE requested_by_user = ${nic}`;

        // Execute the query using the established Postgres connection
        stream<CertRequestOutput, sql:Error?> certRequestStream = self.db->query(query);

        
        return from CertRequestOutput request in certRequestStream
            select request;
        
    }
}




