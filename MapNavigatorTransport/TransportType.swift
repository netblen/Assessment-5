//
//  TransportType.swift
//  MapNavigatorTransport
//
//  Created by netblen on 17-02-2026.
//

import Foundation
import MapKit

enum TransportType: String, CaseIterable, Hashable {
    case automobile = "Auto"
    case transit = "Transit"
    case walking = "Walk"
    case cycling = "Cycle"
    
    var mapKitType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .transit: return .transit
        case .walking: return .walking
        case .cycling: return .walking
        }
    }
}
