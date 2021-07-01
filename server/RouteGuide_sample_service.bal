import ballerina/grpc;
import ballerina/time;

listener grpc:Listener ep = new (8980);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR, descMap: getDescriptorMap()}
service "RouteGuide" on ep {

    isolated remote function GetFeature(Point point) returns Feature|error {
        Feature?|error feature = featureFromPoint(point);
        if feature is Feature || feature is error {
            return feature;
        } else {
            return {location: {latitude: 0, longitude: 0}, name: ""};
        }
    }

    remote function ListFeatures(Rectangle rectangle) returns stream<Feature, grpc:Error?>|error {
        Feature[] selectedFeatures = [];
        foreach Feature feature in FEATURES {
            if inRange(feature.location, rectangle) {
                selectedFeatures.push(feature);
            }
        }
        return selectedFeatures.toStream();
    }

    remote function RecordRoute(stream<Point, grpc:Error?> clientStream) returns RouteSummary|error {
        Point? lastPoint = ();
        int pointCount = 0;
        int featureCount = 0;
        int distance = 0;

        decimal startTime = time:monotonicNow();
        error? e = clientStream.forEach(function(Point p) {
            pointCount += 1;
            if pointExistsInFeatures(FEATURES, p) {
                featureCount += 1;
            }

            if lastPoint is Point {
                distance = calculateDistance(<Point>lastPoint, p);
            }
            lastPoint = p;
        });
        decimal endTime = time:monotonicNow();
        int elapsedTime = <int>(endTime - startTime);
        return {point_count: pointCount, feature_count: featureCount, distance: distance, elapsed_time: elapsedTime};
    }

    remote function RouteChat(RouteGuideRouteNoteCaller caller, stream<RouteNote, grpc:Error?> clientNotesStream) returns error? {
        check clientNotesStream.forEach(function(RouteNote note) {
            future<error?> f1 = start sendRouteNotesFromLocation(caller, note.location);
            lock {
                ROUTE_NOTES.push(note);
            }
            error? waitErr = wait f1;
        });
    }
}

