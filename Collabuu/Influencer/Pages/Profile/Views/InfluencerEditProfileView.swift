import SwiftUI

struct InfluencerEditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InfluencerEditProfileViewModel()
    @StateObject private var formValidator = FormValidator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header Section
                headerSection
                
                // Profile Form Sections
                VStack(spacing: AppSpacing.lg) {
                    personalInfoSection
                    profileDetailsSection
                    socialMediaSection
                }
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.backgroundSecondary)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.hasUnsavedChanges {
                    Button("Save") {
                        viewModel.saveProfile()
                    }
                    .labelLarge(AppColors.secondary)
                    .fontWeight(.semibold)
                    .disabled(viewModel.isLoading)
                }
                
                Menu {
                    if viewModel.hasUnsavedChanges {
                        Button("Discard Changes") {
                            viewModel.discardChanges()
                        }
                    }
                    
                    Button("Upload Photo") {
                        viewModel.showingImagePicker = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onChange(of: viewModel.firstName) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.lastName) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.username) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.email) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.bio) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.location) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.website) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.instagramHandle) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.tiktokHandle) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.youtubeHandle) { _ in viewModel.checkForChanges() }
        .standardizedAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            config: .errorAlert(message: viewModel.errorMessage ?? "") {
                viewModel.errorMessage = nil
            }
        )
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage) {
                viewModel.uploadProfileImage()
            }
        }
        .overlay(
            Group {
                if viewModel.showingSaveSuccess {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Profile saved successfully")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.green)
                        .cornerRadius(AppSpacing.radiusMD)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingSaveSuccess)
                }
            }
        )
        .onAppear {
            viewModel.loadProfile()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Update Your Profile")
                .headlineMedium(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Keep your profile information current to attract better collaboration opportunities")
                .bodyLarge(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.lg)
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Personal Information", icon: "person.circle")
            
            VStack(spacing: AppSpacing.md) {
                // Profile Image
                profileImageSection
                
                // Basic Info
                VStack(spacing: AppSpacing.md) {
                    StandardizedFormField(
                        title: "First Name",
                        text: $viewModel.firstName,
                        placeholder: "Enter first name",
                        isRequired: true,
                        errorMessage: formValidator.errors["firstName"]
                    )
                    
                    StandardizedFormField(
                        title: "Last Name",
                        text: $viewModel.lastName,
                        placeholder: "Enter last name",
                        isRequired: true,
                        errorMessage: formValidator.errors["lastName"]
                    )
                }
                
                StandardizedFormField(
                    title: "Username",
                    text: $viewModel.username,
                    placeholder: "Enter username",
                    isRequired: true,
                    errorMessage: formValidator.errors["username"]
                )
                
                StandardizedFormField(
                    title: "Email",
                    text: $viewModel.email,
                    placeholder: "Enter email address",
                    keyboardType: .emailAddress,
                    isRequired: true,
                    errorMessage: formValidator.errors["email"],
                    leadingIcon: "envelope"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var profileDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Profile Details", icon: "doc.text")
            
            VStack(spacing: AppSpacing.md) {
                StandardizedFormField(
                    title: "Bio",
                    text: $viewModel.bio,
                    placeholder: "Tell others about yourself and what makes you unique...",
                    isMultiline: true,
                    minHeight: 100
                )
                
                StandardizedFormField(
                    title: "Location",
                    text: $viewModel.location,
                    placeholder: "Enter your location",
                    leadingIcon: "location"
                )
                
                StandardizedFormField(
                    title: "Website",
                    text: $viewModel.website,
                    placeholder: "Enter your website URL",
                    keyboardType: .URL,
                    leadingIcon: "link"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var socialMediaSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Social Media", icon: "at")
            
            VStack(spacing: AppSpacing.md) {
                StandardizedFormField(
                    title: "Instagram Handle",
                    text: $viewModel.instagramHandle,
                    placeholder: "Enter Instagram username",
                    leadingIcon: "camera"
                )
                
                StandardizedFormField(
                    title: "TikTok Handle",
                    text: $viewModel.tiktokHandle,
                    placeholder: "Enter TikTok username",
                    leadingIcon: "music.note"
                )
                
                StandardizedFormField(
                    title: "YouTube Handle",
                    text: $viewModel.youtubeHandle,
                    placeholder: "Enter YouTube channel",
                    leadingIcon: "play.rectangle"
                )
                
                StandardizedFormField(
                    title: "Twitter Handle",
                    text: $viewModel.twitterHandle,
                    placeholder: "Enter Twitter username",
                    leadingIcon: "bird"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppSpacing.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusLG)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    private var profileImageSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("Profile Photo")
                    .labelLarge(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Button(action: {
                viewModel.selectProfileImage()
            }) {
                VStack(spacing: AppSpacing.sm) {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.secondary, lineWidth: 3)
                            )
                    } else {
                        Circle()
                            .fill(AppColors.secondary.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(AppColors.secondary)
                                    
                                    Text("Add Photo")
                                        .labelSmall(AppColors.secondary)
                                        .fontWeight(.medium)
                                }
                            )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.secondary)
            
            Text(title)
                .titleMedium(AppColors.textPrimary)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - View Model

@MainActor
class InfluencerEditProfileViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var username = ""
    @Published var email = ""
    @Published var bio = ""
    @Published var location = ""
    @Published var website = ""
    @Published var instagramHandle = ""
    @Published var tiktokHandle = ""
    @Published var youtubeHandle = ""
    @Published var twitterHandle = ""
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasUnsavedChanges = false
    @Published var showingImagePicker = false
    @Published var selectedImage: UIImage?
    @Published var showingSaveSuccess = false
    
    func loadProfile() {
        // TODO: Load existing profile data from API/Database
        // For now, populate with sample data or leave empty
    }
    
    func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // TODO: Implement save profile logic with API
                try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API call
                
                await MainActor.run {
                    self.isLoading = false
                    self.showingSaveSuccess = true
                    // Success handling
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func selectProfileImage() {
        // TODO: Implement image picker
        print("Profile image selection")
    }
    
    func checkForChanges() {
        hasUnsavedChanges = true
    }
    
    func discardChanges() {
        // TODO: Implement discard changes logic
        print("Discard changes")
    }
    
    func uploadProfileImage() {
        // TODO: Implement upload profile image logic
        print("Upload profile image")
    }
}

#Preview {
    InfluencerEditProfileView()
} 