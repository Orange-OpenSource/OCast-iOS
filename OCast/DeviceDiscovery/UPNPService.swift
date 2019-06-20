//
// UPNPService.swift
//
// Copyright 2019 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

typealias UPNPServiceProtocolCompletionHandler = ((Result<UPNPDevice, UPNPServiceProtocolError>)) -> Void

/// UPNP service errors.
enum UPNPServiceProtocolError: Error {
    case httpRequest(HTTPRequestError), badContent
}

/// Protocol to manage UPNP behavior.
protocol UPNPServiceProtocol {
    func device(fromLocation location: String, completionHandler: @escaping UPNPServiceProtocolCompletionHandler)
}

/// Class to manage UPNP behavior.
class UPNPService: UPNPServiceProtocol {
    
    /// The regular expresssion used to extract the UUID from a M-SEARCH response or the UDN field
    private static let regularExpression = try? NSRegularExpression(pattern: "^uuid:([^:]*)")
    
    /// The URLSession used to launch the request.
    private let urlSession: URLSessionProtocol
    
    /// Initializes a new UPNP service with an url session.
    ///
    /// - Parameter urlSession: The URLSession used to launch the request.
    init(urlSession: URLSessionProtocol = URLSession(configuration: .default)) {
        self.urlSession = urlSession
    }
    
    // MARK: Internal methods
    
    /// Extracts the device unique ID from a string.
    ///
    /// - Parameter USN: The string to parse.
    /// - Returns: The device unique ID.
    static func extractUUID(from string: String) -> String? {
        guard let result = UPNPService.regularExpression?.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)),
            result.numberOfRanges == 2,
            let range = Range(result.range(at: 1), in: string) else { return nil }
        
        return String(string[range])
    }
    
    /// Creates a new device from a location URL.
    ///
    /// - Parameters:
    ///   - location: The location from the SSDP response.
    ///   - completionHandler: The completion handler called at the end containing the new device.
    func device(fromLocation location: String, completionHandler: @escaping UPNPServiceProtocolCompletionHandler) {
        let headers = ["Date": dateFormatter.string(from: Date())]
        HTTPRequest.launch(urlSession: self.urlSession,
                           url: location,
                           httpHeaders: headers,
                           completion: { [weak self] result in
            switch result {
            case .success(let data, let responseHeaders):
                if let device = self?.device(from: data, httpHeaders: responseHeaders) {
                    DispatchQueue.main.async {
                        completionHandler(.success(device))
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler(.failure(.badContent))
                    }
                }
            case .failure(let error):
                completionHandler(.failure(.httpRequest(error)))
            }
        })
    }
    
    // MARK: Private methods
    
    /// The dateformatter to send the date header (RFC 7231).
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    
    /// Creates a new device from the location end point response.
    ///
    /// - Parameters:
    ///   - data: The data representing the response.
    ///   - httpHeaders: The HTTP response headers.
    /// - Returns: The new device or `nil` if an error occurs.
    private func device(from data: Data?, httpHeaders: [AnyHashable: Any]) -> UPNPDevice? {
        guard let data = data,
            let applicationURLString = applicationURL(fromHttpHeaders: httpHeaders),
            let applicationURL = URL(string: applicationURLString),
            let ipAddress = applicationURL.host,
            let xmlRootElement = XMLReader().parse(data: data),
            let xmlDeviceElement = xmlRootElement["root"]?["device"],
            let friendlyName = xmlDeviceElement["friendlyName"]?.value,
            let manufacturer = xmlDeviceElement["manufacturer"]?.value,
            let modelName = xmlDeviceElement["modelName"]?.value,
            let UDN = xmlDeviceElement["UDN"]?.value else { return nil }
        
        return UPNPDevice(baseURL: applicationURL,
                      ipAddress: ipAddress,
                      servicePort: UInt16(applicationURL.port ?? 80),
                      deviceID: UPNPService.extractUUID(from: UDN) ?? UDN,
                      friendlyName: friendlyName,
                      manufacturer: manufacturer,
                      modelName: modelName)
    }
    
    /// Returns the application URL from an HTTP response.
    ///
    /// - Parameter httpHeaders: The HTTP response headers.
    /// - Returns: The application URL or `nil`if an error occurs.
    private func applicationURL(fromHttpHeaders httpHeaders: [AnyHashable: Any]) -> String? {
        let applicationDIALURL = httpHeaders["Application-DIAL-URL"] as? String
        let applicationURL = httpHeaders["Application-URL"] as? String
        
        return applicationDIALURL ?? applicationURL
    }
}
