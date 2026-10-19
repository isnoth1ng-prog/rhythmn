import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var newReleases: [Track] = []
    @Published var recommendations: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    func loadContent() async {
        isLoading = true
        errorMessage = nil
        do {
            async let releases = api.getNewReleases()
            async let recs = api.getRecommendations(seedId: nil)
            newReleases = try await releases
            recommendations = try await recs
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
