import ballerina/grpc;
import ballerina/io;
// import ballerina/lang.runtime;

RouteGuideClient ep = check new ("http://localhost:8980");

public function main() returns error? {
    // Simple RPC
    Feature feature = check ep->GetFeature({latitude: 406109563, longitude: -742186778});
    io:println(feature);

    // Server streaming
    Rectangle rectangle = {
        lo: {latitude: 400000000, longitude: -750000000}, 
        hi: {latitude: 420000000, longitude: -730000000}
    };
    stream<Feature, grpc:Error?> features = check ep->ListFeatures(rectangle);
    error? e = features.forEach(function (Feature f) {
        io:println(f);
    });
    io:println(e);

    // Client streaming
    Point[] points = [
        {latitude: 406109563, longitude: -742186778},
        {latitude: 411733222, longitude: -744228360},
        {latitude: 744228334, longitude: -742186778}
    ];
    RecordRouteStreamingClient recordRouteStrmClient = check ep->RecordRoute();
    foreach Point p in points {
        check recordRouteStrmClient->sendPoint(p);
    }
    check recordRouteStrmClient->complete();
    RouteSummary? routeSummary = check recordRouteStrmClient->receiveRouteSummary();
    io:println(routeSummary);

    // bidi
    RouteNote[] routeNotes = [
        {location: {latitude: 406109563, longitude: -742186778}, message: "m1"},
        {location: {latitude: 411733222, longitude: -744228360}, message: "m2"},
        {location: {latitude: 406109563, longitude: -742186778}, message: "m3"}
    ];
    RouteChatStreamingClient routeClient = check ep->RouteChat();
    foreach RouteNote n in routeNotes {
        check routeClient->sendRouteNote(n);
    }
    check routeClient->complete();
    RouteNote? receiveRouteNote = check routeClient->receiveRouteNote();
    while receiveRouteNote != () {
        io:println(receiveRouteNote);
        receiveRouteNote = check routeClient->receiveRouteNote();
    }
}

