import SwiftUI

struct BusinessEditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BusinessEditProfileViewModel()
    @StateObject private var formValidator = FormValidator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header Section
                headerSection
                
                // Profile Form Sections
                VStack(spacing: AppSpacing.lg) {
                    businessInfoSection
                    contactDetailsSection
                    businessDetailsSection
                    settingsSection
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
        .onAppear {
            viewModel.loadProfile()
        }
        .onChange(of: viewModel.businessName) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.businessCategory) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.businessDescription) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.businessEmail) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.phoneNumber) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.website) { _ in viewModel.checkForChanges() }
        .onChange(of: viewModel.businessAddress) { _ in viewModel.checkForChanges() }
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
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Update Your Business")
                .headlineMedium(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Keep your business information current to attract the right influencers and partners")
                .bodyLarge(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.lg)
    }
    
    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Business Information", icon: "building.2")
            
            VStack(spacing: AppSpacing.md) {
                // Business Logo
                businessLogoSection
                
                // Basic Business Info
                StandardizedFormField(
                    title: "Business Name",
                    text: $viewModel.businessName,
                    placeholder: "Enter business name",
                    isRequired: true,
                    errorMessage: formValidator.errors["businessName"]
                )
                
                StandardizedFormField(
                    title: "Business Category",
                    text: $viewModel.businessCategory,
                    placeholder: "e.g., Restaurant, Retail, Technology",
                    isRequired: true,
                    errorMessage: formValidator.errors["businessCategory"]
                )
                
                StandardizedFormField(
                    title: "Business Description",
                    text: $viewModel.businessDescription,
                    placeholder: "Describe your business, what you do, and what makes you unique...",
                    isMultiline: true,
                    minHeight: 100
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
    
    private var contactDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Contact Details", icon: "phone.circle")
            
            VStack(spacing: AppSpacing.md) {
                StandardizedFormField(
                    title: "Business Email",
                    text: $viewModel.businessEmail,
                    placeholder: "Enter business email",
                    keyboardType: .emailAddress,
                    isRequired: true,
                    errorMessage: formValidator.errors["businessEmail"],
                    leadingIcon: "envelope"
                )
                
                StandardizedFormField(
                    title: "Phone Number",
                    text: $viewModel.phoneNumber,
                    placeholder: "Enter phone number",
                    keyboardType: .phonePad,
                    leadingIcon: "phone"
                )
                
                StandardizedFormField(
                    title: "Website",
                    text: $viewModel.website,
                    placeholder: "Enter website URL",
                    keyboardType: .URL,
                    leadingIcon: "link"
                )
                
                StandardizedFormField(
                    title: "Business Address",
                    text: $viewModel.businessAddress,
                    placeholder: "Enter business address",
                    leadingIcon: "location"
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
    
    private var businessDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Business Details", icon: "chart.bar")
            
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    StandardizedFormField(
                        title: "Founded Year",
                        text: $viewModel.foundedYear,
                        placeholder: "e.g., 2020",
                        keyboardType: .numberPad
                    )
                    
                    StandardizedFormField(
                        title: "Employee Count",
                        text: $viewModel.employeeCount,
                        placeholder: "e.g., 1-10",
                        keyboardType: .numberPad
                    )
                }
                
                StandardizedFormField(
                    title: "Business Hours",
                    text: $viewModel.businessHours,
                    placeholder: "e.g., Mon-Fri 9AM-6PM",
                    isMultiline: true,
                    minHeight: 80
                )
                
                StandardizedFormField(
                    title: "Target Audience",
                    text: $viewModel.targetAudience,
                    placeholder: "Describe your ideal customers and target demographics...",
                    isMultiline: true,
                    minHeight: 80
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
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Social Media & Settings", icon: "gear")
            
            VStack(spacing: AppSpacing.md) {
                StandardizedFormField(
                    title: "Instagram Handle",
                    text: $viewModel.instagramHandle,
                    placeholder: "Enter Instagram username",
                    leadingIcon: "camera"
                )
                
                StandardizedFormField(
                    title: "Facebook Page",
                    text: $viewModel.facebookPage,
                    placeholder: "Enter Facebook page URL",
                    leadingIcon: "person.3"
                )
                
                StandardizedFormField(
                    title: "LinkedIn Company",
                    text: $viewModel.linkedinCompany,
                    placeholder: "Enter LinkedIn company URL",
                    leadingIcon: "link"
                )
                
                // Business Visibility Toggle
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Business Visibility")
                        .labelLarge(AppColors.textPrimary)
                        .fontWeight(.medium)
                    
                    Toggle(isOn: $viewModel.isBusinessVisible) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Make business discoverable")
                                .bodyMedium(AppColors.textPrimary)
                                .fontWeight(.medium)
                            
                            Text("Allow influencers to find and connect with your business")
                                .bodySmall(AppColors.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.secondary))
                }
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
    
    private var businessLogoSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("Business Logo")
                    .labelLarge(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Button(action: {
                viewModel.selectBusinessLogo()
            }) {
                VStack(spacing: AppSpacing.sm) {
                    if let businessLogo = viewModel.businessLogo {
                        Image(uiImage: businessLogo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMD))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                                    .stroke(AppColors.secondary, lineWidth: 3)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMD)
                            .fill(AppColors.secondary.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "building.2")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(AppColors.secondary)
                                    
                                    Text("Add Logo")
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
class BusinessEditProfileViewModel: ObservableObject {
    // Business Information
    @Published var businessName = ""
    @Published var businessCategory = ""
    @Published var businessDescription = ""
    @Published var businessLogo: UIImage?
    
    // Contact Details
    @Published var businessEmail = ""
    @Published var phoneNumber = ""
    @Published var website = ""
    @Published var businessAddress = ""
    
    // Business Details
    @Published var foundedYear = ""
    @Published var employeeCount = ""
    @Published var businessHours = ""
    @Published var targetAudience = ""
    
    // Social Media & Settings
    @Published var instagramHandle = ""
    @Published var facebookPage = ""
    @Published var linkedinCompany = ""
    @Published var isBusinessVisible = true
    
    // State
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProfile() {
        // TODO: Load existing business profile data from API/Database
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
    
    func selectBusinessLogo() {
        // TODO: Implement image picker for business logo
        print("Business logo selection")
    }
}

#Preview {
    BusinessEditProfileView()
} 