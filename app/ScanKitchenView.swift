import SwiftUI
import PhotosUI

// MARK: - Scan Kitchen View (photo-picker + upload)
struct ScanKitchenView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Image picking
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var uiImages: [UIImage] = []
    
    // Networking state
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview selected photos or a placeholder icon
                if uiImages.isEmpty {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(uiImages.indices, id: \.self) { idx in
                                Image(uiImage: uiImages[idx])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 110, height: 110)
                                    .clipped()
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Button to pick photos
                PhotosPicker(selection: $pickerItems,
                             maxSelectionCount: 4,
                             matching: .images) {
                    Label("Select Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                             .buttonStyle(.borderedProminent)
                
                // Upload action or progress indicator
                if isUploading {
                    ProgressView("Uploading…")
                } else {
                    Button("Upload & Save") {
                        Task { await uploadFirstPhoto() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(uiImages.isEmpty)
                }
                
                // Error text
                if let msg = errorMessage {
                    Text(msg)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scan Kitchen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: pickerItems) { _ in
                Task { await loadSelectedImages() }
            }
        }
    }
    
    // MARK: - Helpers
    /// Convert PhotosPicker items into UIImages
    private func loadSelectedImages() async {
        uiImages.removeAll()
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                uiImages.append(img)
            }
        }
    }
    
    /// Upload the first photo and store the returned kitchen_id
    private func uploadFirstPhoto() async {
        guard let first = uiImages.first,
              let jpeg = first.jpegData(compressionQuality: 0.8) else { return }
        
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        
        let boundary = UUID().uuidString
        guard var request = buildMultipartRequest(boundary: boundary, data: jpeg) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let kid = json["kitchen_id"] as? String {
                UserDefaults.standard.set(kid, forKey: "kitchenID")
                dismiss()
            } else {
                throw URLError(.cannotParseResponse)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Build multipart/form-data request
    private func buildMultipartRequest(boundary: String, data: Data) -> URLRequest? {
        guard let url = URL(string: "http://localhost:8000/register-kitchen") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"kitchen.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        return req
    }
}

#Preview {
    ScanKitchenView()
}
