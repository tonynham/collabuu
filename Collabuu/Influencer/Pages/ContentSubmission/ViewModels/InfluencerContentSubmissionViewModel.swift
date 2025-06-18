import Foundation
import SwiftUI
import PhotosUI

@MainActor
class InfluencerContentSubmissionViewModel: ObservableObject {
    // Campaign Information
    @Published var campaign: Campaign?
    @Published var campaignRequirements: [ContentRequirement] = []
    @Published var submissionDeadline: Date?
    
    // Content Creation
    @Published var selectedContentType: ContentType = .image
    @Published var contentCaption: String = ""
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var selectedVideos: [PhotosPickerItem] = []
    @Published var uploadedImages: [UploadedMedia] = []
    @Published var uploadedVideos: [UploadedMedia] = []
    
    // Content Details
    @Published var contentTitle: String = ""
    @Published var contentDescription: String = ""
    @Published var hashtags: [String] = []
    @Published var mentionedAccounts: [String] = []
    @Published var scheduledPostTime: Date?
    @Published var isScheduled: Bool = false
    
    // Submission Management
    @Published var submissions: [ContentSubmission] = []
    @Published var draftSubmissions: [DraftSubmission] = []
    @Published var selectedSubmission: ContentSubmission?
    @Published var showingSubmissionDetail: Bool = false
    
    // Upload Progress
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadedFiles: [String] = []
    
    // Approval Workflow
    @Published var submissionStatus: SubmissionStatus = .draft
    @Published var businessFeedback: [BusinessFeedback] = []
    @Published var revisionRequests: [RevisionRequest] = []
    @Published var showingRevisionDetail: Bool = false
    
    // Templates and Guidelines
    @Published var contentTemplates: [ContentTemplate] = []
    @Published var brandGuidelines: BrandGuidelines?
    @Published var selectedTemplate: ContentTemplate?
    @Published var showingTemplates: Bool = false
    
    // Performance Tracking
    @Published var submissionMetrics: [SubmissionMetrics] = []
    @Published var showingMetrics: Bool = false
    
    // State Management
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    
    // Form Validation
    @Published var hasUnsavedChanges: Bool = false
    @Published var showingDiscardAlert: Bool = false
    
    private let apiService = APIService.shared
    private let campaignId: String
    
    init(campaignId: String) {
        self.campaignId = campaignId
        loadCampaignData()
    }
    
    // MARK: - Data Loading
    
    func loadCampaignData() {
        isLoading = true
        
        Task {
            do {
                async let campaignTask = apiService.getCampaignDetails(campaignId)
                async let requirementsTask = apiService.getCampaignRequirements(campaignId)
                async let submissionsTask = apiService.getContentSubmissions(campaignId)
                async let templatesTask = apiService.getContentTemplates(campaignId)
                async let guidelinesTask = apiService.getBrandGuidelines(campaignId)
                async let draftsTask = apiService.getDraftSubmissions(campaignId)
                
                let (campaign, requirements, submissions, templates, guidelines, drafts) = try await (
                    campaignTask, requirementsTask, submissionsTask, templatesTask, guidelinesTask, draftsTask
                )
                
                await MainActor.run {
                    self.campaign = campaign
                    self.campaignRequirements = requirements
                    self.submissions = submissions
                    self.contentTemplates = templates
                    self.brandGuidelines = guidelines
                    self.draftSubmissions = drafts
                    self.submissionDeadline = campaign.endDate
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading campaign data: \(error)")
                    self.loadSampleDataAsFallback()
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Content Creation
    
    func processSelectedMedia() {
        Task {
            isUploading = true
            uploadProgress = 0.0
            
            // Process Images
            for (index, item) in selectedImages.enumerated() {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let uploadedMedia = try await uploadMedia(data: data, type: .image)
                        await MainActor.run {
                            self.uploadedImages.append(uploadedMedia)
                            self.uploadProgress = Double(index + 1) / Double(selectedImages.count + selectedVideos.count)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    }
                }
            }
            
            // Process Videos
            for (index, item) in selectedVideos.enumerated() {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let uploadedMedia = try await uploadMedia(data: data, type: .video)
                        await MainActor.run {
                            self.uploadedVideos.append(uploadedMedia)
                            self.uploadProgress = Double(selectedImages.count + index + 1) / Double(selectedImages.count + selectedVideos.count)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to upload video: \(error.localizedDescription)"
                    }
                }
            }
            
            await MainActor.run {
                self.isUploading = false
                self.selectedImages.removeAll()
                self.selectedVideos.removeAll()
                self.hasUnsavedChanges = true
            }
        }
    }
    
    private func uploadMedia(data: Data, type: MediaType) async throws -> UploadedMedia {
        return try await apiService.uploadMedia(data: data, type: type, campaignId: campaignId)
    }
    
    // MARK: - Submission Management
    
    func saveDraft() {
        isSaving = true
        
        Task {
            do {
                let draft = DraftSubmission(
                    id: UUID().uuidString,
                    campaignId: campaignId,
                    contentType: selectedContentType,
                    title: contentTitle,
                    caption: contentCaption,
                    description: contentDescription,
                    hashtags: hashtags,
                    mentionedAccounts: mentionedAccounts,
                    uploadedImages: uploadedImages,
                    uploadedVideos: uploadedVideos,
                    scheduledPostTime: scheduledPostTime,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                let savedDraft = try await apiService.saveDraftSubmission(draft)
                
                await MainActor.run {
                    if let index = self.draftSubmissions.firstIndex(where: { $0.id == savedDraft.id }) {
                        self.draftSubmissions[index] = savedDraft
                    } else {
                        self.draftSubmissions.append(savedDraft)
                    }
                    
                    self.hasUnsavedChanges = false
                    self.isSaving = false
                    self.showSuccessMessage("Draft saved successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save draft: \(error.localizedDescription)"
                    self.isSaving = false
                }
            }
        }
    }
    
    func submitContent() {
        guard validateSubmission() else { return }
        
        Task {
            do {
                let submission = ContentSubmissionRequest(
                    campaignId: campaignId,
                    contentType: selectedContentType,
                    title: contentTitle,
                    caption: contentCaption,
                    description: contentDescription,
                    hashtags: hashtags,
                    mentionedAccounts: mentionedAccounts,
                    uploadedImages: uploadedImages,
                    uploadedVideos: uploadedVideos,
                    scheduledPostTime: scheduledPostTime
                )
                
                let submittedContent = try await apiService.submitContent(submission)
                
                await MainActor.run {
                    self.submissions.append(submittedContent)
                    self.clearForm()
                    self.showSuccessMessage("Content submitted successfully!")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to submit content: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func validateSubmission() -> Bool {
        guard !contentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Content title is required"
            return false
        }
        
        guard !contentCaption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Content caption is required"
            return false
        }
        
        guard !uploadedImages.isEmpty || !uploadedVideos.isEmpty else {
            errorMessage = "At least one image or video is required"
            return false
        }
        
        // Check campaign requirements
        for requirement in campaignRequirements {
            if !meetsRequirement(requirement) {
                errorMessage = "Content doesn't meet requirement: \(requirement.description)"
                return false
            }
        }
        
        return true
    }
    
    private func meetsRequirement(_ requirement: ContentRequirement) -> Bool {
        switch requirement.type {
        case .minimumImages:
            return uploadedImages.count >= requirement.minimumCount
        case .minimumVideos:
            return uploadedVideos.count >= requirement.minimumCount
        case .requiredHashtags:
            return requirement.requiredHashtags.allSatisfy { hashtags.contains($0) }
        case .mentionBrand:
            return mentionedAccounts.contains(requirement.brandAccount)
        case .minimumCaptionLength:
            return contentCaption.count >= requirement.minimumLength
        }
    }
    
    // MARK: - Template Management
    
    func applyTemplate(_ template: ContentTemplate) {
        contentTitle = template.title
        contentCaption = template.caption
        contentDescription = template.description
        hashtags = template.hashtags
        mentionedAccounts = template.mentionedAccounts
        selectedTemplate = template
        hasUnsavedChanges = true
        showingTemplates = false
    }
    
    // MARK: - Revision Handling
    
    func loadRevisionRequests() {
        Task {
            do {
                let requests = try await apiService.getRevisionRequests(campaignId)
                
                await MainActor.run {
                    self.revisionRequests = requests
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load revision requests: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func submitRevision(for request: RevisionRequest) {
        Task {
            do {
                let revision = ContentRevision(
                    requestId: request.id,
                    contentType: selectedContentType,
                    title: contentTitle,
                    caption: contentCaption,
                    description: contentDescription,
                    hashtags: hashtags,
                    mentionedAccounts: mentionedAccounts,
                    uploadedImages: uploadedImages,
                    uploadedVideos: uploadedVideos,
                    revisionNotes: "Addressed feedback: \(request.feedback)"
                )
                
                try await apiService.submitRevision(revision)
                
                await MainActor.run {
                    self.loadRevisionRequests()
                    self.clearForm()
                    self.showSuccessMessage("Revision submitted successfully!")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to submit revision: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Performance Metrics
    
    func loadSubmissionMetrics() {
        Task {
            do {
                let metrics = try await apiService.getSubmissionMetrics(campaignId)
                
                await MainActor.run {
                    self.submissionMetrics = metrics
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load metrics: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Form Management
    
    func clearForm() {
        contentTitle = ""
        contentCaption = ""
        contentDescription = ""
        hashtags = []
        mentionedAccounts = []
        uploadedImages = []
        uploadedVideos = []
        scheduledPostTime = nil
        isScheduled = false
        selectedTemplate = nil
        hasUnsavedChanges = false
    }
    
    func loadDraft(_ draft: DraftSubmission) {
        contentTitle = draft.title
        contentCaption = draft.caption
        contentDescription = draft.description
        hashtags = draft.hashtags
        mentionedAccounts = draft.mentionedAccounts
        uploadedImages = draft.uploadedImages
        uploadedVideos = draft.uploadedVideos
        scheduledPostTime = draft.scheduledPostTime
        selectedContentType = draft.contentType
        hasUnsavedChanges = false
    }
    
    func deleteDraft(_ draft: DraftSubmission) {
        Task {
            do {
                try await apiService.deleteDraftSubmission(draft.id)
                
                await MainActor.run {
                    self.draftSubmissions.removeAll { $0.id == draft.id }
                    self.showSuccessMessage("Draft deleted successfully")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete draft: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Hashtag Management
    
    func addHashtag(_ hashtag: String) {
        let cleanHashtag = hashtag.hasPrefix("#") ? String(hashtag.dropFirst()) : hashtag
        if !hashtags.contains(cleanHashtag) && !cleanHashtag.isEmpty {
            hashtags.append(cleanHashtag)
            hasUnsavedChanges = true
        }
    }
    
    func removeHashtag(_ hashtag: String) {
        hashtags.removeAll { $0 == hashtag }
        hasUnsavedChanges = true
    }
    
    func addMention(_ account: String) {
        let cleanAccount = account.hasPrefix("@") ? String(account.dropFirst()) : account
        if !mentionedAccounts.contains(cleanAccount) && !cleanAccount.isEmpty {
            mentionedAccounts.append(cleanAccount)
            hasUnsavedChanges = true
        }
    }
    
    func removeMention(_ account: String) {
        mentionedAccounts.removeAll { $0 == account }
        hasUnsavedChanges = true
    }
    
    // MARK: - Sample Data Fallback
    
    private func loadSampleDataAsFallback() {
        // Sample Campaign
        campaign = Campaign(
            id: campaignId,
            title: "Summer Fashion Collection",
            description: "Promote our new summer collection with authentic lifestyle content",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            budget: 5000.0,
            status: .active
        )
        
        // Sample Requirements
        campaignRequirements = [
            ContentRequirement(
                id: "req1",
                type: .minimumImages,
                description: "At least 2 high-quality images",
                minimumCount: 2,
                requiredHashtags: [],
                brandAccount: "",
                minimumLength: 0
            ),
            ContentRequirement(
                id: "req2",
                type: .requiredHashtags,
                description: "Include brand hashtags",
                minimumCount: 0,
                requiredHashtags: ["#SummerStyle", "#FashionForward"],
                brandAccount: "",
                minimumLength: 0
            ),
            ContentRequirement(
                id: "req3",
                type: .mentionBrand,
                description: "Mention our brand account",
                minimumCount: 0,
                requiredHashtags: [],
                brandAccount: "@fashionbrand",
                minimumLength: 0
            )
        ]
        
        // Sample Templates
        contentTemplates = [
            ContentTemplate(
                id: "temp1",
                title: "Lifestyle Post",
                caption: "Loving this new summer collection! Perfect for those sunny days ☀️",
                description: "Casual lifestyle post showcasing the summer collection",
                hashtags: ["#SummerStyle", "#FashionForward", "#OOTD"],
                mentionedAccounts: ["@fashionbrand"],
                contentType: .image
            ),
            ContentTemplate(
                id: "temp2",
                title: "Unboxing Video",
                caption: "Unboxing my latest fashion haul! Can't wait to style these pieces 📦✨",
                description: "Engaging unboxing video showing product details",
                hashtags: ["#Unboxing", "#FashionHaul", "#SummerStyle"],
                mentionedAccounts: ["@fashionbrand"],
                contentType: .video
            )
        ]
        
        // Sample Brand Guidelines
        brandGuidelines = BrandGuidelines(
            brandColors: ["#FF6B6B", "#4ECDC4", "#45B7D1"],
            brandFonts: ["Helvetica", "Arial"],
            toneOfVoice: "Friendly, authentic, and inspiring",
            dosList: ["Use natural lighting", "Show products in lifestyle settings", "Include diverse models"],
            dontsList: ["Use competitor products", "Post inappropriate content", "Ignore brand values"],
            requiredDisclosures: ["#ad", "#sponsored", "#partnership"]
        )
        
        // Sample Submissions
        submissions = [
            ContentSubmission(
                id: "sub1",
                campaignId: campaignId,
                contentType: .image,
                title: "Summer Vibes",
                caption: "Feeling the summer vibes with this amazing collection! ☀️ #SummerStyle #FashionForward",
                status: .approved,
                submittedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                approvedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                mediaUrls: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
            )
        ]
        
        submissionDeadline = campaign?.endDate
    }
    
    // MARK: - Utility Methods
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showingSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingSuccessMessage = false
        }
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
}

// MARK: - Supporting Models

struct ContentRequirement: Identifiable, Codable {
    let id: String
    let type: RequirementType
    let description: String
    let minimumCount: Int
    let requiredHashtags: [String]
    let brandAccount: String
    let minimumLength: Int
}

enum RequirementType: String, Codable {
    case minimumImages = "minimum_images"
    case minimumVideos = "minimum_videos"
    case requiredHashtags = "required_hashtags"
    case mentionBrand = "mention_brand"
    case minimumCaptionLength = "minimum_caption_length"
}

struct ContentTemplate: Identifiable, Codable {
    let id: String
    let title: String
    let caption: String
    let description: String
    let hashtags: [String]
    let mentionedAccounts: [String]
    let contentType: ContentType
}

struct BrandGuidelines: Codable {
    let brandColors: [String]
    let brandFonts: [String]
    let toneOfVoice: String
    let dosList: [String]
    let dontsList: [String]
    let requiredDisclosures: [String]
}

struct ContentSubmissionRequest: Codable {
    let campaignId: String
    let contentType: ContentType
    let title: String
    let caption: String
    let description: String
    let hashtags: [String]
    let mentionedAccounts: [String]
    let uploadedImages: [UploadedMedia]
    let uploadedVideos: [UploadedMedia]
    let scheduledPostTime: Date?
}

struct ContentSubmission: Identifiable, Codable {
    let id: String
    let campaignId: String
    let contentType: ContentType
    let title: String
    let caption: String
    let status: SubmissionStatus
    let submittedAt: Date
    let approvedAt: Date?
    let mediaUrls: [String]
}

enum SubmissionStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case submitted = "submitted"
    case underReview = "under_review"
    case approved = "approved"
    case rejected = "rejected"
    case needsRevision = "needs_revision"
    case published = "published"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .needsRevision: return "Needs Revision"
        case .published: return "Published"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .submitted: return .blue
        case .underReview: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .needsRevision: return .yellow
        case .published: return .purple
        }
    }
}

struct DraftSubmission: Identifiable, Codable {
    let id: String
    let campaignId: String
    let contentType: ContentType
    let title: String
    let caption: String
    let description: String
    let hashtags: [String]
    let mentionedAccounts: [String]
    let uploadedImages: [UploadedMedia]
    let uploadedVideos: [UploadedMedia]
    let scheduledPostTime: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct UploadedMedia: Identifiable, Codable {
    let id: String
    let url: String
    let type: MediaType
    let filename: String
    let size: Int
    let uploadedAt: Date
}

enum MediaType: String, Codable {
    case image = "image"
    case video = "video"
}

struct RevisionRequest: Identifiable, Codable {
    let id: String
    let submissionId: String
    let feedback: String
    let requestedChanges: [String]
    let deadline: Date
    let createdAt: Date
}

struct ContentRevision: Codable {
    let requestId: String
    let contentType: ContentType
    let title: String
    let caption: String
    let description: String
    let hashtags: [String]
    let mentionedAccounts: [String]
    let uploadedImages: [UploadedMedia]
    let uploadedVideos: [UploadedMedia]
    let revisionNotes: String
}

struct BusinessFeedback: Identifiable, Codable {
    let id: String
    let submissionId: String
    let feedback: String
    let rating: Int
    let createdAt: Date
}

struct SubmissionMetrics: Identifiable, Codable {
    let id: String
    let submissionId: String
    let impressions: Int
    let likes: Int
    let comments: Int
    let shares: Int
    let engagementRate: Double
    let reachRate: Double
    let recordedAt: Date
} 