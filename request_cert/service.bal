import ballerina/http;
import ballerinax/postgresql;
import ballerina/sql;
import ballerinax/postgresql.driver as _;
import ballerina/io;
import ballerina/uuid;

public type DatabaseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DatabaseConfig IDdatabaseConfig = ?;
service / on new http:Listener(7070) {
    private final postgresql:Client db;

    function init() returns error? {
        postgresql:Options postgresqlOptions = {
            connectTimeout: 10
        };
        self.db = check new (IDdatabaseConfig.host,IDdatabaseConfig.user,IDdatabaseConfig.password,IDdatabaseConfig.database,IDdatabaseConfig.port, options = postgresqlOptions);
        io:println("Postgres Database is connected and running successfully...");
    }

    // resource function post grama(string user_id, string name) returns string | error? {
       
    //     string result = check insertData(user_id, name);
    //     return result;
    // }

    resource function post insert_data(string nic, string reason, string document_id) returns sql:ExecutionResult|sql:Error|error?{
        
        uuid:Uuid uuid_request = check uuid:createType1AsRecord();
        //convert uuid to string
        string uuid_request_string = check uuid:toString(uuid_request);
    

        sql:ParameterizedQuery query = `INSERT INTO cert_request(request_id, nic, reason, supporting_documents) VALUES (${uuid_request_string},${nic},${reason}, ${document_id})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }

    resource function post mark_as_completed(string request_id) returns sql:ExecutionResult|sql:Error|error?{
        
        sql:ParameterizedQuery query = `UPDATE cert_request SET status = 'completed' WHERE request_id = ${request_id}`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }

    resource function post mark_as_rejected(string request_id) returns sql:ExecutionResult|sql:Error|error?{
        
        sql:ParameterizedQuery query = `UPDATE cert_request SET status = 'rejected' WHERE request_id = ${request_id}`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }
}




