import SwiftUI

struct ResultView: View {
    let result: KnotResponse
    @ObservedObject var client: KnotNetClient
    @State private var showOriginalImage = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Image Container
                ImageComparisonHeader(result: result, showOriginalImage: $showOriginalImage)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                
                // Segmented Control (Tabs)
                Picker("Ansicht", selection: $selectedTab) {
                    Text("Übersicht").tag(0)
                    Text("Topologie").tag(1)
                    Text("Performance").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Tab Contents
                if selectedTab == 0 {
                    OverviewTab(result: result)
                } else if selectedTab == 1 {
                    TopologyTab(result: result)
                } else {
                    PerformanceTab(result: result)
                }
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.14), Color(red: 0.08, green: 0.12, blue: 0.22)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Knoten-Analyse")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

struct ImageComparisonHeader: View {
    let result: KnotResponse
    @Binding var showOriginalImage: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background skeleton loader while image loads
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
            
            // Image Loader
            let imageUrlString = showOriginalImage ? result.rawImageUrl : result.visualizationUrl
            if let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                } placeholder: {
                    VStack {
                        ProgressView()
                            .tint(.blue)
                        Text("Lade Visualisierung...")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                }
            } else {
                Text("Kein Bild verfügbar")
                    .foregroundColor(.white)
            }
            
            // Toggle overlay button
            Button(action: {
                withAnimation(.spring()) {
                    showOriginalImage.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: showOriginalImage ? "eye" : "eye.slash")
                    Text(showOriginalImage ? "Original" : "Visualisierung")
                }
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(12)
            }
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let result: KnotResponse
    
    // Classify knot based on typical Jones / PD code
    var knotName: String {
        // Typically the backend handles classification, if not let's show a fallback matching table
        let jones = result.topology?.jonesStr ?? ""
        let cleanJones = jones.replacingOccurrences(of: " ", with: "")
        
        if cleanJones.contains("-A^4") || cleanJones.contains("t^-4") || cleanJones.contains("t^3+t^1") {
            return "Kleeblattschlinge (Trefoil Knot - 3_1)"
        } else if cleanJones.contains("A^-8") || cleanJones.contains("t^-2+t^2") {
            return "Achterknoten (Figure-Eight Knot - 4_1)"
        } else if cleanJones == "1" || cleanJones == "1.0" || cleanJones.isEmpty {
            return "Unknoten (Unknot - 0_1)"
        }
        
        return "Komplexer Knoten"
    }
    
    var knotIcon: String {
        if knotName.contains("Kleeblatt") {
            return "leaf.fill"
        } else if knotName.contains("Achter") {
            return "infinity"
        } else if knotName.contains("Unknoten") {
            return "circle.circle"
        }
        return "square.stack.3d.forward.dottedline"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Knot Card
            VStack(spacing: 8) {
                Image(systemName: knotIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding(.bottom, 4)
                
                Text("Erkannter Knotentyp")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                Text(knotName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            
            // Notation Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.purple)
                    Text("Knoten-Notation")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                let compactNotation = result.knotNotation?.compact ?? ""
                Text(compactNotation.isEmpty ? "Keine Notation verfügbar" : compactNotation)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                
                Text("Repräsentiert die Kreuzungsdurchläufe: O = Over (Oben), U = Under (Unten)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Key Invariants Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InvariantCell(title: "Kreuzungen", value: "\(result.topology?.nCrossings ?? 0)", subtitle: "Modell-Vorhersage", icon: "arrow.3.trianglepath")
                InvariantCell(title: "Writhe", value: "\(result.topology?.writhe ?? 0)", subtitle: "Richtungssumme", icon: "skew")
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Topology Tab
struct TopologyTab: View {
    let result: KnotResponse
    
    var body: some View {
        VStack(spacing: 16) {
            // Jones Polynomial
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "function")
                        .foregroundColor(.cyan)
                    Text("Jones-Polynom")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                let jonesStr = result.topology?.jonesStr ?? ""
                Text(jonesStr.isEmpty ? "1" : jonesStr)
                    .font(.system(.title3, design: .serif))
                    .italic()
                    .foregroundColor(.cyan)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                
                Text("Das Jones-Polynom ist eine topologische Invariante. Knoten mit unterschiedlichen Polynomen sind topologisch verschieden.")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Planar Diagram (PD) Code
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                        .foregroundColor(.orange)
                    Text("Planar Diagram (PD-Code)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                let pdCodeStr = result.pdCode?.pdCodeStr ?? ""
                Text(pdCodeStr.isEmpty ? "Kein PD-Code generiert" : pdCodeStr)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                
                Text("Der PD-Code kodiert die Struktur des Knotendiagramms. Er beschreibt für jede Kreuzung die vier ein- und auslaufenden Segmente.")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Gauss & DT Codes
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.green)
                    Text("Weitere Codes")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Divider()
                    .background(Color.white.opacity(0.1))
                
                CodeRow(title: "Gauß-Code", value: result.topology?.gaussCode ?? "")
                CodeRow(title: "Dowker-Thistlethwaite (DT)", value: result.topology?.dtNotation ?? "")
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Performance Tab
struct PerformanceTab: View {
    let result: KnotResponse
    
    // Sort timings to display nicely
    var sortedTimings: [(String, Double)] {
        (result.timing ?? [:]).sorted(by: { $0.value > $1.value })
    }
    
    var totalTime: Double {
        (result.timing ?? [:]).values.reduce(0, +)
    }

    
    var body: some View {
        VStack(spacing: 16) {
            // Total Time Card
            VStack(spacing: 6) {
                Text("Gesamte Rechenzeit")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.2f s", totalTime))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Detailed Table
            VStack(alignment: .leading, spacing: 14) {
                Text("Pipeline-Phasen")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                ForEach(sortedTimings, id: \.0) { phase, duration in
                    VStack(spacing: 6) {
                        HStack {
                            Text(phase.capitalized)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f ms", duration * 1000))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                        
                        // Progress bar representation
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(duration / max(totalTime, 0.001)), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - UI Helpers

struct InvariantCell: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct CodeRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value.isEmpty ? "Kein Code vorhanden" : value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
