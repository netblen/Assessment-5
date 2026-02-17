//
//  ContentView.swift
//  MapNavigatorTransport
//
//  Created by netblen on 17-02-2026.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    //default location
    let lasalleCoords = CLLocationCoordinate2D(latitude: 45.4919, longitude: -73.5794)
    
    @State private var camera: MapCameraPosition = .automatic
    @State private var currentCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.4919, longitude: -73.5794)
    @State private var zoomDistance: Double = 2000
    //search state
    @State private var searchText = ""
    @State private var destination: MKMapItem?
    @State private var errorMessage: String?
    //transport mode selection
    @State private var selectedTransport: TransportType = .automobile
    //route drawing
    @State private var route: MKRoute?
    @State private var travelTime: String?
    @State private var distance: String?
    
    var body: some View {
        ZStack {
            //map Implementation

            Map(position: $camera) {
                Marker("Collège LaSalle", systemImage: "mappin.circle.fill", coordinate: lasalleCoords)
                    .tint(.red)
                
                if let userLoc = locationManager.userLocation {
                    Marker("You", coordinate: userLoc)
                        .tint(.blue)
                }
                
                if let dest = destination {
                    Marker("Destination", coordinate: dest.placemark.coordinate)
                        .tint(.green)
                }
                
                if let route = route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(.standard)
            //tracking camera for center the zoom
            .onMapCameraChange { context in
                currentCenter = context.camera.centerCoordinate
            }
            
            //zoom UI bttons
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: { zoom(0.5) }) {
                            Image(systemName: "plus.magnifyingglass")
                                .padding().background(.ultraThinMaterial).clipShape(Circle())
                        }
                        Button(action: { zoom(1.5) }) {
                            Image(systemName: "minus.magnifyingglass")
                                .padding().background(.ultraThinMaterial).clipShape(Circle())
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            
            //Search and Transport bar
            VStack {
                Spacer()
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red).padding().background(.white).cornerRadius(10)
                }
                
                VStack(spacing: 15) {
                    //transportartion Selector
                    Picker("Transport Mode", selection: $selectedTransport) {
                        ForEach(TransportType.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTransport) { _ in calculateRoute() }
                    
                    
                    
                    HStack {
                        TextField("Search destination...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        Button("Search") { performSearch() }
                            .buttonStyle(.borderedProminent)
                    }
                    
                    //route details
                    if let time = travelTime, let dist = distance {
                        HStack {
                            Text("Dist: \(dist) km")
                            Spacer()
                            Text("Time: \(time) min")
                        }
                        .font(.caption).bold()
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
        }
        .onAppear {
            camera = .camera(MapCamera(centerCoordinate: lasalleCoords, distance: zoomDistance))
        }
    }
    
    
    private func zoom(_ factor: Double) {
        zoomDistance *= factor
        withAnimation {
            camera = .camera(MapCamera(centerCoordinate: currentCenter, distance: zoomDistance))
        }
    }
    
    
    
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(center: lasalleCoords, latitudinalMeters: 5000, longitudinalMeters: 5000)
        
        MKLocalSearch(request: request).start { response, error in
            if let error = error {
                errorMessage = "Search failed: \(error.localizedDescription)"
                return
            }
            guard let item = response?.mapItems.first else {
                errorMessage = "No results found"
                return
            }
            destination = item
            errorMessage = nil
            calculateRoute()
        }
    }
    
    private func calculateRoute() {
        guard let destination = destination else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lasalleCoords))
        request.destination = destination
        request.transportType = selectedTransport.mapKitType
        
        MKDirections(request: request).calculate { response, error in
            guard let route = response?.routes.first else { return }
            self.route = route
            
            self.distance = String(format: "%.2f", route.distance / 1000)
            self.travelTime = String(format: "%.0f", route.expectedTravelTime / 60)
            
            var routeRect = route.polyline.boundingMapRect

            let padding = 300.0
            routeRect = routeRect.insetBy(dx: -padding, dy: -padding)
            

            withAnimation {
                camera = .rect(routeRect)
            }
        }
    }
    
    
}



#Preview {
    ContentView()
}
