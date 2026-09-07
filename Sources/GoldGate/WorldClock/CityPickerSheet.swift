import SwiftUI

public struct CityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorldClockViewModel
    @State private var searchText: String = ""
    @State private var selectedContinent: String = "All"
    
    let continents = ["All", "North America", "Europe", "Asia", "South America", "Oceania", "Middle East", "Africa"]
    
    private var filteredCities: [City] {
        let searched = CityDatabase.search(query: searchText)
        if selectedContinent == "All" {
            return searched
        }
        return searched.filter { $0.continent.lowercased() == selectedContinent.lowercased() }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Continent Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(continents, id: \.self) { cont in
                                Button {
                                    selectedContinent = cont
                                } label: {
                                    Text(cont)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedContinent == cont ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedContinent == cont ? Color.orange : Color(white: 0.15))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 4)
                    
                    // City Results List
                    List {
                        ForEach(filteredCities) { city in
                            Button {
                                viewModel.addPillow(from: city)
                                dismiss()
                            } label: {
                                cityRow(city: city)
                            }
                            .listRowBackground(Color(red: 0.08, green: 0.08, blue: 0.1))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add World Pillow")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search city, country, or timezone...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func cityRow(city: City) -> some View {
        let cityTimeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
        let formatter = DateFormatter()
        formatter.timeZone = cityTimeZone
        formatter.dateFormat = "h:mm a"
        let cityTime = formatter.string(from: viewModel.effectiveDate)
        
        let suitability = CallOverlapCalculator.currentSuitability(for: cityTimeZone, date: viewModel.effectiveDate)
        
        return HStack(spacing: 12) {
            Text(city.flag)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(city.countryOrRegion) • \(city.continent)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(cityTime)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(suitability.statusColor)
                        .frame(width: 6, height: 6)
                    Text(suitability.badgeText)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(suitability.statusColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
