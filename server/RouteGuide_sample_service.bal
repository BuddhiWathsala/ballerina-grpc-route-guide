import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR, descMap: getDescriptorMap()}
service "RouteGuide" on ep {

    remote function GetFeature(Point value) returns Feature|error {
    }
    remote function RecordRoute(stream<Point, grpc:Error?> clientStream) returns RouteSummary|error {
    }
    remote function ListFeatures(Rectangle value) returns stream<Feature, error?>|error {
    }
    remote function RouteChat(stream<RouteNote, grpc:Error?> clientStream) returns stream<RouteNote, error?>|error {
    }
}

