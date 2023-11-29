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
        self.db = check new (IDdatabaseConfig.host,IDdatabaseConfig.user,IDdatabaseConfig.password,IDdatabaseConfig.database,IDdatabaseConfig.port);
        io:println("Postgres Database is connected and running successfully...");
    }

    // resource function post grama(string user_id, string name) returns string | error? {
       
    //     string result = check insertData(user_id, name);
    //     return result;
    // }

    resource function post insertData(string nic, string reason, string document_id) returns sql:ExecutionResult|sql:Error {
        postgresql:Options postgresqlOptions = {
            connectTimeout: 10
        };
        uuid:Uuid uuid_request = check uuid:createType1AsRecord();
    

        sql:ParameterizedQuery query = `INSERT INTO cert_request(request_id, nic, reason, supporting_documents) VALUES (${uuid_request},${nic},${reason}, ${document_id})`;
        sql:ExecutionResult|sql:Error result = self.db->execute(query);

        return result;
    }
}


