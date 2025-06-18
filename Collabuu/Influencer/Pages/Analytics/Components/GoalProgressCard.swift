import SwiftUI

struct GoalProgressCard: View {
    let goal: GoalProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: goal.type.icon)
                    .font(.title3)
                    .foregroundColor(goal.isAchieved ? .green : .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal.isAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(currentValueText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("of \(targetValueText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    Text("\(goal.progress * 100, specifier: "%.0f")% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !goal.isAchieved {
                        Text(remainingText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(goal.isAchieved ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var progressText: String {
        if goal.isAchieved {
            return "Goal Achieved! 🎉"
        } else {
            let remaining = goal.target - goal.current
            return "\(remaining.formatted()) \(goal.unit) to go"
        }
    }
    
    private var currentValueText: String {
        return "\(goal.current.formatted())\(goal.unit)"
    }
    
    private var targetValueText: String {
        return "\(goal.target.formatted())\(goal.unit)"
    }
    
    private var remainingText: String {
        let remaining = goal.target - goal.current
        return "\(remaining.formatted())\(goal.unit) remaining"
    }
    
    private var progressColor: Color {
        if goal.isAchieved {
            return .green
        } else if goal.progress >= 0.8 {
            return .orange
        } else if goal.progress >= 0.5 {
            return .blue
        } else {
            return .gray
        }
    }
}

struct GoalProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            GoalProgressCard(
                goal: GoalProgress(
                    type: .engagement,
                    current: 4.8,
                    target: 5.0,
                    unit: "%"
                )
            )
            
            GoalProgressCard(
                goal: GoalProgress(
                    type: .earnings,
                    current: 4200.0,
                    target: 4000.0,
                    unit: "$"
                )
            )
            
            GoalProgressCard(
                goal: GoalProgress(
                    type: .followers,
                    current: 45230,
                    target: 50000,
                    unit: ""
                )
            )
        }
        .padding()
    }
} 