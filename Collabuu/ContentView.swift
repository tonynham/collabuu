import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Collabuu")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Connect • Collaborate • Grow")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Feature Cards
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "building.2.fill",
                        title: "For Businesses",
                        description: "Create campaigns and connect with influencers",
                        color: .blue
                    )
                    
                    FeatureCard(
                        icon: "megaphone.fill",
                        title: "For Influencers",
                        description: "Discover opportunities and earn credits",
                        color: .purple
                    )
                    
                    FeatureCard(
                        icon: "person.fill",
                        title: "For Customers",
                        description: "Find deals and earn loyalty rewards",
                        color: .green
                    )
                }
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    // TODO: Navigate to authentication flow
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarHidden(true)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 