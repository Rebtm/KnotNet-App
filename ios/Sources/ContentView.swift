import SwiftUI

struct ContentView: View {
    @StateObject private var client = KnotNetClient()
    
    @State private var showingImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    
    @State private var showingSettings = false
    @State private var tempIP = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.14), Color(red: 0.08, green: 0.12, blue: 0.22)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Welcome & Logo Area
                    VStack(spacing: 12) {
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10)
                            .padding(.top, 20)
                        
                        Text("KnotNet")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("End-to-End Knot Recognition Pipeline")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 10)
                    
                    // Main Camera Action Area
                    VStack(spacing: 16) {
                        if let selectedImage = selectedImage {
                            // Image Preview
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal)
                        } else {
                            // Placeholder
                            VStack(spacing: 16) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Noch kein Foto aufgenommen")
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Actions
                        HStack(spacing: 16) {
                            // Open Camera
                            Button(action: {
                                pickerSourceType = .camera
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Foto aufnehmen")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.2), radius: 5)
                            }
                            
                            // Photo Library
                            Button(action: {
                                pickerSourceType = .photoLibrary
                                showingImagePicker = true
                            }) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Upload / Run Section
                    if let img = selectedImage, !client.isUploading {
                        Button(action: {
                            client.uploadImage(img)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Knoten analysieren")
                            }
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: .purple.opacity(0.2), radius: 5)
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Status / Loading / Results Overlay
                    VStack {
                        if client.isUploading {
                            VStack(spacing: 16) {
                                ProgressView(value: client.uploadProgress)
                                    .tint(.purple)
                                    .progressViewStyle(.linear)
                                    .frame(height: 8)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                    Text(client.progressMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else if let error = client.errorMessage {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Verbindungsfehler")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else if let _ = client.lastResult {
                            NavigationLink(destination: ResultView(result: client.lastResult!, client: client)) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.headline)
                                    Text("Analyseergebnisse anzeigen")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(height: 100) // Fixed reserve space for state changes
                    
                    Spacer()
                    
                    // Server Configuration footer
                    Button(action: {
                        tempIP = client.serverIP
                        showingSettings = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "network")
                            Text("Mac Server IP: \(client.serverIP)")
                                .font(.footnote.weight(.medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: pickerSourceType)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(client: client, isPresented: $showingSettings, tempIP: $tempIP)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var client: KnotNetClient
    @Binding var isPresented: Bool
    @Binding var tempIP: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("KnotNet Server Verbindung")) {
                    TextField("IP-Adresse des Mac", text: $tempIP)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                    
                    Text("Dein Mac und iPhone müssen im selben WLAN sein. Starte das Python-Backend auf dem Mac und gib die dort angezeigte IP-Adresse hier ein.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Info")) {
                    HStack {
                        Text("Port")
                        Spacer()
                        Text("8000 (Standard)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("API-Status")
                        Spacer()
                        Text(client.errorMessage == nil ? "Verbunden" : "Verbindungsprobleme")
                            .foregroundColor(client.errorMessage == nil ? .green : .red)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        client.serverIP = tempIP
                        isPresented = false
                    }
                }
            }
        }
    }
}
