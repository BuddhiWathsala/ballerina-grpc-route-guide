import ballerina/grpc;
import ballerina/io;

RouteGuideClient ep = check new ("http://localhost:8980");

public function main() returns error? {
    // Simple RPC
    Feature feature = check ep->GetFeature({latitude: 406109563, longitude: -742186778});
    io:println(`GetFeature: lat=${feature.location.latitude},  lon=${feature.location.longitude}`);

    // Server streaming
    Rectangle rectangle = {
        lo: {latitude: 400000000, longitude: -750000000},
        hi: {latitude: 420000000, longitude: -730000000}
    };
    io:println(`ListFeatures: lowLat=${rectangle.lo.latitude},  lowLon=${rectangle.lo.latitude}, hiLat=${rectangle.hi.latitude},  hiLon=${rectangle.hi.latitude}`);
    stream<Feature, grpc:Error?> features = check ep->ListFeatures(rectangle);
    error? e = features.forEach(function(Feature f) {
        io:println(`Result: lat=${f.location.latitude}, lon=${f.location.longitude}`);
    });

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
    if routeSummary is RouteSummary {
        io:println(`Finished trip with ${routeSummary.point_count} points. Passed ${routeSummary.feature_count} features. "Travelled ${routeSummary.distance} meters. It took ${routeSummary.elapsed_time} seconds.`);
    }

    // Bidirectional streaming
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
        io:println(`Got message '${receiveRouteNote.message}' at lat=${receiveRouteNote.location.latitude}, lon=${receiveRouteNote.location.longitude}`);
        receiveRouteNote = check routeClient->receiveRouteNote();
    }
}

