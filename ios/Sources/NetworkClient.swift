import Foundation
import UIKit
import Combine

class KnotNetClient: ObservableObject {
    @Published var isUploading = false
    @Published var progressMessage = ""
    @Published var uploadProgress: Double = 0.0
    @Published var lastResult: KnotResponse?
    @Published var errorMessage: String?
    
    // Store server IP in UserDefaults so it persists
    @Published var serverIP: String {
        didSet {
            UserDefaults.standard.set(serverIP, forKey: "KnotNetServerIP")
        }
    }
    
    var baseURLString: String {
        return "http://\(serverIP.trimmingCharacters(in: .whitespacesAndNewlines)):8000"
    }
    
    init() {
        // Default to a placeholder, user can change in settings.
        self.serverIP = UserDefaults.standard.string(forKey: "KnotNetServerIP") ?? "192.168.1.100"
    }
    
    func uploadImage(_ image: UIImage) {
        guard let url = URL(string: "\(baseURLString)/predict") else {
            self.errorMessage = "Ungültige Server-URL. Bitte IP-Adresse in den Einstellungen prüfen."
            return
        }
        
        // Resize image if too large (e.g. iPhone photos can be 12MP+ which takes too long to upload over Wi-Fi)
        let targetSize = CGSize(width: 1536, height: 1536)
        let resizedImage = image.resizeToMaxDimension(targetSize.width)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            self.errorMessage = "Bild konnte nicht komprimiert werden."
            return
        }
        
        self.isUploading = true
        self.errorMessage = nil
        self.progressMessage = "Bereite Bild vor..."
        self.uploadProgress = 0.1
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"knot_upload.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let session = URLSession.shared
        self.progressMessage = "Sende Bild an Mac..."
        self.uploadProgress = 0.3
        
        let task = session.uploadTask(with: request, from: body) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    self?.errorMessage = "Netzwerkfehler: \(error.localizedDescription)\n\nBitte prüfen:\n1. Sind Mac und iPhone im selben WLAN?\n2. Läuft das Python-Backend auf dem Mac?\n3. Ist die IP-Adresse (\(self?.serverIP ?? "")) korrekt?"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Keine gültige HTTP-Antwort erhalten."
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if let data = data, let errorMsg = String(data: data, encoding: .utf8) {
                        self?.errorMessage = "Server-Fehler (\(httpResponse.statusCode)): \(errorMsg)"
                    } else {
                        self?.errorMessage = "Server-Fehler (\(httpResponse.statusCode))"
                    }
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Keine Daten empfangen."
                    return
                }
                
                do {
                    self?.progressMessage = "Verarbeite Ergebnisse..."
                    self?.uploadProgress = 0.9
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(KnotResponse.self, from: data)
                    self?.lastResult = result
                    self?.uploadProgress = 1.0
                } catch {
                    self?.errorMessage = "Dekodierungsfehler: \(error.localizedDescription)\n\nStelle sicher, dass die Backend-Version übereinstimmt."
                    print("JSON Decoding Error: \(error)")
                }
            }
        }
        
        task.resume()
    }
}

// Helper to scale down high-resolution camera images to speed up network uploads
extension UIImage {
    func resizeToMaxDimension(_ maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let ratio = min(widthRatio, heightRatio, 1.0) // Don't upscale
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
}
