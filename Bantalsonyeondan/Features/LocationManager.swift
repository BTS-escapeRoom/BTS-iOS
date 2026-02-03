//
//  LocationManager.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 5/28/25.
//

import SwiftUI
import CoreLocation

/// 비동기 위치 획득을 제공하는 매니저
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 현재 위치를 비동기로 반환
    func getLocation() async throws -> CLLocationCoordinate2D {
        // 1) 권한 요청 및 상태 확인
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            // 권한 요청 후 대기
            manager.requestWhenInUseAuthorization()
            let newStatus = await withCheckedContinuation { (continuation: CheckedContinuation<CLAuthorizationStatus, Never>) in
                self.authContinuation = continuation
            }
            guard newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways else {
                throw CLError(.denied)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            throw CLError(.denied)
        }

        // 2) 위치 요청 및 반환
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocationCoordinate2D, Error>) in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authContinuation?.resume(returning: status)
        authContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        locationContinuation?.resume(returning: loc.coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}
